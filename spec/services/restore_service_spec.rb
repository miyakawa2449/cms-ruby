require "rails_helper"

RSpec.describe RestoreService do
  let(:backup_keys) do
    {
      database: "daily/2026/04/20/database_file.dump.gz",
      storage:  "daily/2026/04/20/storage_file.tar.gz",
      config:   "daily/2026/04/20/config_file.tar.gz"
    }
  end
  let(:service) { described_class.new(backup_keys: backup_keys) }

  let(:mock_s3) { instance_double(S3Service) }
  let(:mock_db_restore)  { instance_double(DatabaseRestoreService, execute: nil) }
  let(:mock_st_restore)  { instance_double(StorageRestoreService, execute: nil) }
  let(:mock_cfg_restore) { instance_double(ConfigRestoreService, execute: nil) }

  let(:restore_dir) { Rails.root.join("tmp", "restore").to_s }

  before do
    allow(S3Service).to receive(:new).and_return(mock_s3)
    allow(mock_s3).to receive(:download) do |object_key:, destination:|
      FileUtils.mkdir_p(File.dirname(destination))
      File.write(destination, "fake content")
    end

    allow(DatabaseRestoreService).to receive(:new).and_return(mock_db_restore)
    allow(StorageRestoreService).to receive(:new).and_return(mock_st_restore)
    allow(ConfigRestoreService).to receive(:new).and_return(mock_cfg_restore)

    allow(BackupMailer).to receive_message_chain(:restore_success, :deliver_later)
    allow(BackupMailer).to receive_message_chain(:restore_failed, :deliver_later)

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:delete)
  end

  after do
    FileUtils.rm_rf(restore_dir)
  end

  describe "#execute" do
    context "when all restores succeed" do
      it "creates a BackupLog with backup_type: restore and in_progress" do
        expect(BackupLog).to receive(:create!).with(
          hash_including(backup_type: :restore, status: :in_progress)
        ).and_call_original
        service.execute
      end

      it "downloads all three files from S3" do
        expect(mock_s3).to receive(:download).exactly(3).times
        service.execute
      end

      it "calls all three restore services" do
        expect(mock_db_restore).to receive(:execute)
        expect(mock_st_restore).to receive(:execute)
        expect(mock_cfg_restore).to receive(:execute)
        service.execute
      end

      it "passes downloaded file paths to restore services" do
        expect(DatabaseRestoreService).to receive(:new).with(
          match(/database_file\.dump\.gz/)
        ).and_return(mock_db_restore)
        service.execute
      end

      it "marks BackupLog as success" do
        service.execute
        log = BackupLog.restore.last
        expect(log.status).to eq("success")
        expect(log.completed_at).to be_present
      end

      it "sends restore success notification" do
        expect(BackupMailer).to receive(:restore_success).with(instance_of(BackupLog))
          .and_return(double(deliver_later: nil))
        service.execute
      end

      it "cleans up downloaded temp files in ensure" do
        allow(File).to receive(:exist?).and_return(true)
        expect(File).to receive(:delete).at_least(3).times
        service.execute
      end
    end

    context "when a restore service fails" do
      before do
        allow(mock_db_restore).to receive(:execute).and_raise(RuntimeError, "pg_restore failed")
      end

      it "marks BackupLog as failed with error_message" do
        expect { service.execute }.to raise_error(RuntimeError)
        log = BackupLog.restore.last
        expect(log.status).to eq("failed")
        expect(log.error_message).to eq("pg_restore failed")
        expect(log.completed_at).to be_present
      end

      it "sends restore failure notification" do
        expect(BackupMailer).to receive(:restore_failed).with(
          instance_of(BackupLog), instance_of(RuntimeError)
        ).and_return(double(deliver_later: nil))
        expect { service.execute }.to raise_error(RuntimeError)
      end

      it "re-raises the error" do
        expect { service.execute }.to raise_error(RuntimeError, "pg_restore failed")
      end

      it "still cleans up temp files" do
        allow(File).to receive(:exist?).and_return(true)
        expect(File).to receive(:delete).at_least(1).times
        expect { service.execute }.to raise_error(RuntimeError)
      end
    end

    context "when notification fails" do
      before do
        allow(BackupMailer).to receive(:restore_success).and_raise(StandardError, "SMTP error")
        allow(Rails.logger).to receive(:warn)
      end

      it "does not raise an error" do
        expect { service.execute }.not_to raise_error
      end

      it "logs the notification failure" do
        expect(Rails.logger).to receive(:warn).with(/notification failed.*SMTP error/)
        service.execute
      end

      it "still marks BackupLog as success" do
        service.execute
        expect(BackupLog.restore.last.status).to eq("success")
      end
    end

    context "when some backup_keys are nil" do
      let(:backup_keys) { { database: "daily/2026/04/20/database_file.dump.gz", storage: nil, config: nil } }

      it "only restores the database" do
        expect(mock_db_restore).to receive(:execute)
        expect(mock_st_restore).not_to receive(:execute)
        expect(mock_cfg_restore).not_to receive(:execute)
        service.execute
      end

      it "does not download nil keys" do
        expect(mock_s3).to receive(:download).once
        service.execute
      end
    end
  end

  describe "Property 16: 復元ログ記録" do
    # Feature: phase-7.3-auto-backup, Property 16: 復元ログ記録
    it "records BackupLog with backup_type restore on success" do
      service.execute
      log = BackupLog.restore.last
      expect(log).to be_present
      expect(log.status).to eq("success")
      expect(log.started_at).to be_present
      expect(log.completed_at).to be_present
    end

    it "calls restore_success mailer on success" do
      expect(BackupMailer).to receive(:restore_success).with(instance_of(BackupLog))
        .and_return(double(deliver_later: nil))
      service.execute
    end

    it "calls restore_failed mailer on failure" do
      allow(mock_db_restore).to receive(:execute).and_raise(RuntimeError, "error")
      expect(BackupMailer).to receive(:restore_failed).with(
        instance_of(BackupLog), instance_of(RuntimeError)
      ).and_return(double(deliver_later: nil))
      expect { service.execute }.to raise_error(RuntimeError)
    end
  end
end

RSpec.describe DatabaseRestoreService do
  let(:restore_dir) { Rails.root.join("tmp", "restore").to_s }
  let(:dump_gz) { File.join(restore_dir, "database_test.dump.gz") }

  before do
    FileUtils.mkdir_p(restore_dir)
    # Create a fake .dump.gz (gzip-wrapped content)
    Zlib::GzipWriter.open(dump_gz) { |gz| gz.write("fake dump data") }
  end

  after { FileUtils.rm_rf(restore_dir) }

  describe "#execute" do
    it "decompresses the .gz file before restoring" do
      decompressed = dump_gz.sub(/\.gz\z/, "")
      allow_any_instance_of(described_class).to receive(:restore_database)
      described_class.new(dump_gz).execute
      # Decompressed file is cleaned up in ensure, so we check the restore was called
      expect(File.exist?(decompressed)).to be false
    end

    it "raises an error when pg_restore fails" do
      allow_any_instance_of(described_class).to receive(:system).and_return(false)
      status_double = instance_double(Process::Status, success?: false, exitstatus: 1)
      allow(Process).to receive(:last_status).and_return(status_double)

      # Use a real-looking command stub that fails
      allow_any_instance_of(described_class).to receive(:restore_database) do
        raise "Database restore failed with exit code 1"
      end

      expect { described_class.new(dump_gz).execute }.to raise_error(/Database restore failed/)
    end

    it "cleans up the decompressed file even on error" do
      allow_any_instance_of(described_class).to receive(:restore_database)
        .and_raise(RuntimeError, "restore error")

      decompressed = dump_gz.sub(/\.gz\z/, "")
      expect { described_class.new(dump_gz).execute }.to raise_error(RuntimeError)
      expect(File.exist?(decompressed)).to be false
    end
  end
end

RSpec.describe StorageRestoreService do
  # 重要: このサービスは Rails.root 直下の storage/ に展開する破壊的な処理。
  # 実リポジトリを壊さないよう、必ず一時ディレクトリを Rails.root に差し替えてテストする
  let(:fake_root) { Pathname.new(Dir.mktmpdir) }
  let(:restore_dir) { fake_root.join("tmp", "restore").to_s }
  let(:storage_dir) { fake_root.join("storage").to_s }
  let(:archive) { File.join(restore_dir, "storage_test.tar.gz") }

  before do
    allow(Rails).to receive(:root).and_return(fake_root)
    FileUtils.mkdir_p(restore_dir)
    FileUtils.mkdir_p(storage_dir)
    # Create a real tar.gz for testing
    test_file = File.join(storage_dir, "test.txt")
    File.write(test_file, "test content")
    system("tar", "-czf", archive, "-C", fake_root.to_s, "storage")
  end

  after { FileUtils.rm_rf(fake_root) }

  describe "#execute" do
    it "extracts the archive to storage/ directory" do
      described_class.new(archive).execute
      expect(File.exist?(File.join(storage_dir, "test.txt"))).to be true
    end

    it "raises an error when tar fails" do
      allow_any_instance_of(described_class).to receive(:system).and_return(false)
      expect { described_class.new(archive).execute }.to raise_error(/Storage restore failed/)
    end
  end
end

RSpec.describe ConfigRestoreService do
  # 重要: このサービスは Rails.root 直下の .env / master.key 等を上書きする破壊的な処理。
  # 過去にこのspecが実リポジトリの .env をテスト実行のたびに破壊していた事故があった。
  # 必ず一時ディレクトリを Rails.root に差し替えてテストすること
  let(:fake_root) { Pathname.new(Dir.mktmpdir) }
  let(:restore_dir) { fake_root.join("tmp", "restore").to_s }
  let(:archive) { File.join(restore_dir, "config_test.tar.gz") }
  let(:staging) { File.join(restore_dir, "config_source") }

  before do
    allow(Rails).to receive(:root).and_return(fake_root)
    FileUtils.mkdir_p(restore_dir)
    FileUtils.mkdir_p(staging)
    File.write(File.join(staging, ".env"), "SECRET=restored")
    system("tar", "-czf", archive, "-C", staging, ".")
  end

  after { FileUtils.rm_rf(fake_root) }

  describe "#execute" do
    it "restores files from the archive to Rails.root" do
      described_class.new(archive).execute
      expect(File.read(fake_root.join(".env"))).to include("SECRET=restored")
    end

    it "raises an error when tar fails" do
      allow_any_instance_of(described_class).to receive(:system).and_return(false)
      expect { described_class.new(archive).execute }.to raise_error(/Config extract failed/)
    end
  end
end
