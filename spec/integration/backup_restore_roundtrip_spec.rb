require "rails_helper"

# Task 19.2: バックアップ→復元ラウンドトリップ統合テスト
# External boundaries mocked: Aws::S3::Client, pg_dump, pg_restore, notifications
# Service orchestration runs for real: BackupService, RestoreService, and all sub-services
RSpec.describe "Task 19.2: バックアップ→復元ラウンドトリップ統合テスト", type: :integration do
  let(:fake_root)      { Pathname.new(Dir.mktmpdir("roundtrip_")) }
  let(:s3_store)       { {} }
  let(:mock_s3_client) { instance_double(Aws::S3::Client) }

  # Original file contents for post-restore verification
  let(:env_content)          { "DATABASE_URL=postgres://localhost/app\nSECRET_KEY=abc123\n" }
  let(:credentials_content)  { "encrypted_credentials_binary_xyz" }
  let(:storage_file_content) { "This is a fake uploaded file.\nLine 2.\n" }

  before do
    allow(Rails).to receive(:root).and_return(fake_root)
    FileUtils.mkdir_p(fake_root.join("tmp", "backup"))
    FileUtils.mkdir_p(fake_root.join("tmp", "restore"))

    # Setup original storage files
    FileUtils.mkdir_p(fake_root.join("storage", "app", "uploads"))
    File.write(fake_root.join("storage", "app", "uploads", "image.txt"), storage_file_content)

    # Setup original config files
    FileUtils.mkdir_p(fake_root.join("config"))
    File.write(fake_root.join(".env"),                         env_content)
    File.write(fake_root.join("config", "credentials.yml.enc"), credentials_content)

    # Skip real pg_dump
    allow_any_instance_of(DatabaseBackupService).to receive(:create_dump) do |svc|
      svc.send(:ensure_backup_dir)
      path = svc.send(:temp_file_path, "database", "dump")
      File.binwrite(path, "FAKE_PGDUMP_BINARY_CONTENT")
      path
    end

    # Skip real pg_restore
    allow_any_instance_of(DatabaseRestoreService).to receive(:restore_database)

    # AWS credential stubs
    stub_const("ENV", ENV.to_h.merge(
      "AWS_BACKUP_ACCESS_KEY_ID"     => "test_key",
      "AWS_BACKUP_SECRET_ACCESS_KEY" => "test_secret",
      "AWS_BACKUP_REGION"            => "ap-northeast-1",
      "S3_BACKUP_BUCKET"             => "test-bucket"
    ))
    allow(Aws::S3::Client).to receive(:new).and_return(mock_s3_client)

    # In-memory S3: put_object stores content
    allow(mock_s3_client).to receive(:put_object) do |params|
      body = params[:body]
      s3_store[params[:key]] = body.respond_to?(:read) ? body.read : body.to_s
    end

    # In-memory S3: get_object writes stored content to response_target
    allow(mock_s3_client).to receive(:get_object) do |params|
      content = s3_store[params[:key]]
      unless content
        raise Aws::S3::Errors::NoSuchKey.new(
          Seahorse::Client::RequestContext.new, "No such key: #{params[:key]}"
        )
      end
      FileUtils.mkdir_p(File.dirname(params[:response_target]))
      File.binwrite(params[:response_target], content)
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
    allow(BackupMailer).to receive(:restore_success).and_return(mail_delivery)
    allow(BackupMailer).to receive(:restore_failed).and_return(mail_delivery)
    allow(SlackNotifier).to receive(:notify_backup_status)
  end

  after { FileUtils.rm_rf(fake_root) }

  # Helper: バックアップを実行して S3 キーを返す
  def run_backup_and_get_keys
    BackupService.new(backup_type: "daily").execute
    {
      database: s3_store.keys.find { |k| k.include?("/database_") },
      storage:  s3_store.keys.find { |k| k.include?("/storage_") },
      config:   s3_store.keys.find { |k| k.include?("/config_") }
    }
  end

  describe "Storage ラウンドトリップ" do
    it "storage/ファイルがバックアップ→復元後に元の内容で存在する" do
      backup_keys = run_backup_and_get_keys
      expect(backup_keys[:storage]).to be_present

      # 障害シミュレーション：storage/ を削除
      FileUtils.rm_rf(fake_root.join("storage"))
      expect(fake_root.join("storage", "app", "uploads", "image.txt")).not_to exist

      # 復元実行
      RestoreService.new(backup_keys: backup_keys).execute

      # 復元確認
      restored = fake_root.join("storage", "app", "uploads", "image.txt")
      expect(restored).to exist
      expect(File.read(restored)).to eq(storage_file_content)
    end
  end

  describe "Config ラウンドトリップ" do
    it ".env がバックアップ→復元後に元の内容で存在する" do
      backup_keys = run_backup_and_get_keys

      File.delete(fake_root.join(".env"))
      File.delete(fake_root.join("config", "credentials.yml.enc"))

      RestoreService.new(backup_keys: backup_keys).execute

      expect(File.read(fake_root.join(".env"))).to eq(env_content)
    end

    it "config/credentials.yml.enc がバックアップ→復元後に元の内容で存在する" do
      backup_keys = run_backup_and_get_keys

      File.delete(fake_root.join(".env"))
      File.delete(fake_root.join("config", "credentials.yml.enc"))

      RestoreService.new(backup_keys: backup_keys).execute

      expect(File.read(fake_root.join("config", "credentials.yml.enc"))).to eq(credentials_content)
    end
  end

  describe "完全ラウンドトリップ（database/storage/config 同時復元）" do
    it "全ファイルが復元後に正しい内容で存在する" do
      backup_keys = run_backup_and_get_keys

      # 全ファイルを削除
      FileUtils.rm_rf(fake_root.join("storage"))
      File.delete(fake_root.join(".env"))
      File.delete(fake_root.join("config", "credentials.yml.enc"))

      RestoreService.new(backup_keys: backup_keys).execute

      expect(File.read(fake_root.join("storage", "app", "uploads", "image.txt"))).to eq(storage_file_content)
      expect(File.read(fake_root.join(".env"))).to eq(env_content)
      expect(File.read(fake_root.join("config", "credentials.yml.enc"))).to eq(credentials_content)
    end

    it "復元後に BackupLog が restore タイプで success 記録される" do
      backup_keys = run_backup_and_get_keys

      expect {
        RestoreService.new(backup_keys: backup_keys).execute
      }.to change { BackupLog.where(backup_type: "restore").count }.by(1)

      log = BackupLog.where(backup_type: "restore").last
      expect(log.status).to eq("success")
      expect(log.completed_at).to be_present
    end

    it "復元後に一時ファイルが tmp/restore に残らない" do
      backup_keys = run_backup_and_get_keys
      RestoreService.new(backup_keys: backup_keys).execute

      restore_tmp = fake_root.join("tmp", "restore")
      leftover_files = Dir.glob(File.join(restore_tmp.to_s, "*")).select { |f| File.file?(f) }
      expect(leftover_files).to be_empty, "Temp files remain: #{leftover_files}"
    end
  end

  describe "Feature: phase-7.3-auto-backup, Property 16: 復元ログ記録" do
    it "BackupService → RestoreService で両方の BackupLog が記録される" do
      expect {
        backup_keys = run_backup_and_get_keys
        RestoreService.new(backup_keys: backup_keys).execute
      }.to change(BackupLog, :count).by(2)

      logs = BackupLog.order(started_at: :asc).last(2)
      expect(logs.map(&:backup_type)).to include("daily", "restore")
      expect(logs.map(&:status).uniq).to eq([ "success" ])
    end
  end
end
