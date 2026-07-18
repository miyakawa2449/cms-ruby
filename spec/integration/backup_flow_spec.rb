require "rails_helper"

# Task 19.1: バックアップ→S3アップロード→世代管理 統合テスト
# External boundaries mocked: Aws::S3::Client, pg_dump, notifications
# Service orchestration runs for real: BackupService, DatabaseBackupService,
# StorageBackupService, ConfigBackupService, S3Service, S3RetentionManager
RSpec.describe "Task 19.1: バックアップフロー統合テスト", type: :integration do
  let(:fake_root)      { Pathname.new(Dir.mktmpdir("backup_flow_")) }
  let(:s3_store)       { {} }
  let(:mock_s3_client) { instance_double(Aws::S3::Client) }

  before do
    allow(Rails).to receive(:root).and_return(fake_root)

    # Minimum directory structure
    FileUtils.mkdir_p(fake_root.join("tmp", "backup"))
    FileUtils.mkdir_p(fake_root.join("storage", "app", "uploads"))
    File.write(fake_root.join("storage", "app", "uploads", "photo.txt"), "fake photo data")

    FileUtils.mkdir_p(fake_root.join("config"))
    File.write(fake_root.join(".env"),                         "DATABASE_URL=fake\n")
    File.write(fake_root.join("config", "credentials.yml.enc"), "encrypted_data")

    # Skip real pg_dump; write a fake binary dump file instead
    allow_any_instance_of(DatabaseBackupService).to receive(:create_dump) do |svc|
      svc.send(:ensure_backup_dir)
      path = svc.send(:temp_file_path, "database", "dump")
      File.binwrite(path, "FAKE_PGDUMP_DATA")
      path
    end

    # AWS credential stubs
    stub_const("ENV", ENV.to_h.merge(
      "AWS_BACKUP_ACCESS_KEY_ID"     => "test_key",
      "AWS_BACKUP_SECRET_ACCESS_KEY" => "test_secret",
      "AWS_BACKUP_REGION"            => "ap-northeast-1",
      "S3_BACKUP_BUCKET"             => "test-bucket"
    ))
    allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)

    # In-memory S3: put_object
    allow(mock_s3_client).to receive(:put_object) do |params|
      body = params[:body]
      s3_store[params[:key]] = body.respond_to?(:read) ? body.read : body.to_s
    end

    # In-memory S3: list_objects_v2
    allow(mock_s3_client).to receive(:list_objects_v2) do |params|
      prefix = params[:prefix].to_s
      objects = s3_store.keys.select { |k| k.start_with?(prefix) }.map do |key|
        double("S3Object",
          key: key, size: s3_store[key].bytesize, last_modified: 1.hour.ago, etag: '"abc"')
      end
      double("ListResponse", contents: objects, is_truncated: false, next_continuation_token: nil)
    end

    allow(mock_s3_client).to receive(:delete_object)

    mail_delivery = instance_double(ActionMailer::MessageDelivery, deliver_later: nil)
    allow(BackupMailer).to receive(:backup_success).and_return(mail_delivery)
    allow(BackupMailer).to receive(:backup_failed).and_return(mail_delivery)
    allow(SlackNotifier).to receive(:notify_backup_status)
  end

  after { FileUtils.rm_rf(fake_root) }

  describe "BackupService → S3Service → S3RetentionManager の統合フロー" do
    subject(:run_backup) { BackupService.new(backup_type: "daily").execute }

    it "BackupLog が success ステータスで保存される" do
      expect { run_backup }.to change(BackupLog, :count).by(1)

      log = BackupLog.last
      expect(log.status).to eq("success")
      expect(log.backup_type).to eq("daily")
      expect(log.started_at).to be_present
      expect(log.completed_at).to be_present
    end

    it "database/storage/config の 3 ファイルが S3 にアップロードされる" do
      run_backup

      expect(s3_store.keys.length).to eq(3)
      expect(s3_store.keys).to include(
        a_string_matching(/database/),
        a_string_matching(/storage/),
        a_string_matching(/config/)
      )
    end

    it "S3 キーが daily/YYYY/MM/DD/category_... 形式になる" do
      run_backup

      date_prefix = Time.current.strftime("daily/%Y/%m/%d/")
      s3_store.each_key do |key|
        expect(key).to start_with(date_prefix), "Expected key to start with #{date_prefix}, got: #{key}"
        expect(key).to match(/(database|storage|config)_/)
      end
    end

    it "BackupLog に s3_keys が 3 件記録される" do
      run_backup

      log = BackupLog.last
      expect(log.s3_keys).to be_an(Array)
      expect(log.s3_keys.length).to eq(3)
    end

    it "実行後に一時ファイルが tmp/backup に残らない" do
      run_backup

      remaining = Dir.glob(fake_root.join("tmp", "backup", "**", "*.gz").to_s) +
                  Dir.glob(fake_root.join("tmp", "backup", "**", "*.dump").to_s)
      expect(remaining).to be_empty, "Temp files remain: #{remaining}"
    end

    it "BackupLog に file_size が記録される" do
      run_backup

      expect(BackupLog.last.file_size).to be_positive
    end

    it "成功通知が送信される" do
      mail = instance_double(ActionMailer::MessageDelivery)
      expect(BackupMailer).to receive(:backup_success).and_return(mail)
      expect(mail).to receive(:deliver_later)
      run_backup
    end
  end

  describe "世代管理フロー（保持期間超えのバックアップが削除される）" do
    let(:old_key) { "daily/2026/04/12/database_old.dump.gz" }

    before do
      s3_store[old_key] = "old backup data"

      # Override list_objects_v2 to include the old backup
      allow(mock_s3_client).to receive(:list_objects_v2) do |params|
        prefix = params[:prefix].to_s
        objects = s3_store.keys.select { |k| k.start_with?(prefix) }.map do |key|
          modified = key == old_key ? 9.days.ago : 1.hour.ago
          double("S3Object",
            key: key, size: s3_store[key].bytesize, last_modified: modified, etag: '"abc"')
        end
        double("ListResponse", contents: objects, is_truncated: false, next_continuation_token: nil)
      end
    end

    it "7 日以上前の daily バックアップが S3 から削除される" do
      expect(mock_s3_client).to receive(:delete_object).with(
        hash_including(key: old_key)
      )
      BackupService.new(backup_type: "daily").execute
    end
  end

  describe "Feature: phase-7.3-auto-backup, Property 2: バックアップファイル形式" do
    # S3 key format: {backup_type}/{YYYY}/{MM}/{DD}/{category}_{category}_{YYYYMMDD}_{HHMMSS}_{type}.{ext}
    # The category_ prefix is added by S3Service; the filename itself also starts with category.
    it "各バックアップファイルが日時・タイプを含む正しい形式になる" do
      BackupService.new(backup_type: "daily").execute

      s3_store.each_key do |key|
        parts = key.split("/")
        # Path: daily/YYYY/MM/DD/filename
        expect(parts[0]).to eq("daily")
        expect(parts[1]).to match(/^\d{4}$/)
        expect(parts[2]).to match(/^\d{2}$/)
        expect(parts[3]).to match(/^\d{2}$/)

        filename = parts[4]
        expect(filename).to match(/\d{8}_\d{6}_daily/), "No timestamp in filename: #{filename}"
        expect(filename).to match(/\.(dump\.gz|tar\.gz)$/)
        expect(filename).to match(/^(database|storage|config)_/)
      end
    end
  end
end
