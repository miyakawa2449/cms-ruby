require "rails_helper"

RSpec.describe BackupService do
  let(:backup_type) { "daily" }
  let(:service) { described_class.new(backup_type: backup_type) }

  let(:mock_s3) { instance_double(S3Service, upload: "daily/2026/04/20/database_file.dump.gz", get_latest_backup_size: 5_000_000) }
  let(:mock_db_backup) { instance_double(DatabaseBackupService, execute: "/tmp/backup/database_file.dump.gz") }
  let(:mock_st_backup) { instance_double(StorageBackupService, execute: "/tmp/backup/storage_file.tar.gz") }
  let(:mock_cfg_backup) { instance_double(ConfigBackupService, execute: "/tmp/backup/config_file.tar.gz") }
  let(:mock_retention) { instance_double(S3RetentionManager, cleanup: nil) }

  before do
    allow(S3Service).to receive(:new).and_return(mock_s3)
    allow(DatabaseBackupService).to receive(:new).with(backup_type).and_return(mock_db_backup)
    allow(StorageBackupService).to receive(:new).with(backup_type).and_return(mock_st_backup)
    allow(ConfigBackupService).to receive(:new).with(backup_type).and_return(mock_cfg_backup)
    allow(S3RetentionManager).to receive(:new).with(backup_type).and_return(mock_retention)
    allow(BackupMailer).to receive_message_chain(:backup_success, :deliver_later)
    allow(BackupMailer).to receive_message_chain(:backup_failed, :deliver_later)
    allow(SlackNotifier).to receive(:notify_backup_status)

    # Don't actually delete temp files (they're mocked paths)
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:delete)
  end

  describe "#execute" do
    context "when all backups succeed" do
      it "creates a BackupLog with in_progress status at start" do
        expect(BackupLog).to receive(:create!).with(
          hash_including(backup_type: backup_type, status: :in_progress)
        ).and_call_original

        service.execute
      end

      it "calls all three backup services" do
        expect(mock_db_backup).to receive(:execute)
        expect(mock_st_backup).to receive(:execute)
        expect(mock_cfg_backup).to receive(:execute)
        service.execute
      end

      it "uploads each backup to S3" do
        expect(mock_s3).to receive(:upload).exactly(3).times
        service.execute
      end

      it "runs retention cleanup" do
        expect(mock_retention).to receive(:cleanup)
        service.execute
      end

      it "marks BackupLog as success with completed_at and file_size" do
        service.execute
        log = BackupLog.last
        expect(log.status).to eq("success")
        expect(log.completed_at).to be_present
        expect(log.file_size).to eq(5_000_000)
      end

      it "records s3_keys in BackupLog" do
        allow(mock_s3).to receive(:upload).and_return(
          "daily/2026/04/20/database_file.dump.gz",
          "daily/2026/04/20/storage_file.tar.gz",
          "daily/2026/04/20/config_file.tar.gz"
        )
        service.execute
        expect(BackupLog.last.s3_keys).to match_array([
          "daily/2026/04/20/database_file.dump.gz",
          "daily/2026/04/20/storage_file.tar.gz",
          "daily/2026/04/20/config_file.tar.gz"
        ])
      end

      it "sends success notification via BackupMailer" do
        expect(BackupMailer).to receive(:backup_success).with(instance_of(BackupLog))
          .and_return(double(deliver_later: nil))
        service.execute
      end

      it "sends success notification via SlackNotifier" do
        expect(SlackNotifier).to receive(:notify_backup_status).with(instance_of(BackupLog))
        service.execute
      end

      it "cleans up temp files in ensure" do
        expect(File).to receive(:delete).at_least(3).times
        allow(File).to receive(:exist?).and_return(true)
        service.execute
      end
    end

    context "when a backup service raises an error" do
      before do
        allow(mock_db_backup).to receive(:execute).and_raise(RuntimeError, "Database dump failed")
      end

      it "marks BackupLog as failed with error_message" do
        expect { service.execute }.to raise_error(RuntimeError)
        log = BackupLog.last
        expect(log.status).to eq("failed")
        expect(log.error_message).to eq("Database dump failed")
        expect(log.completed_at).to be_present
      end

      it "sends failure notification via BackupMailer" do
        expect(BackupMailer).to receive(:backup_failed).with(instance_of(BackupLog), instance_of(RuntimeError))
          .and_return(double(deliver_later: nil))
        expect { service.execute }.to raise_error(RuntimeError)
      end

      it "sends failure notification via SlackNotifier" do
        expect(SlackNotifier).to receive(:notify_backup_status).with(instance_of(BackupLog))
        expect { service.execute }.to raise_error(RuntimeError)
      end

      it "still cleans up any temp files that were created before the error" do
        # database backup succeeds (file added to @temp_files), then storage raises
        allow(mock_db_backup).to receive(:execute).and_return("/tmp/backup/database_file.dump.gz")
        allow(mock_st_backup).to receive(:execute).and_raise(RuntimeError, "Storage archive failed")
        allow(File).to receive(:exist?).and_return(true)

        expect(File).to receive(:delete).at_least(1).times
        expect { service.execute }.to raise_error(RuntimeError)
      end

      it "re-raises the original error" do
        expect { service.execute }.to raise_error(RuntimeError, "Database dump failed")
      end
    end

    context "when notification fails" do
      before do
        allow(BackupMailer).to receive(:backup_success).and_raise(StandardError, "SMTP error")
        allow(Rails.logger).to receive(:warn)
      end

      it "does not raise an error — backup is still considered successful" do
        expect { service.execute }.not_to raise_error
      end

      it "logs the notification failure as a warning" do
        expect(Rails.logger).to receive(:warn).with(/notification failed.*SMTP error/)
        service.execute
      end

      it "still marks BackupLog as success" do
        service.execute
        expect(BackupLog.last.status).to eq("success")
      end
    end

    context "when retention cleanup fails" do
      before do
        allow(mock_retention).to receive(:cleanup).and_raise(StandardError, "S3 error")
        allow(Rails.logger).to receive(:warn)
      end

      it "does not raise an error" do
        expect { service.execute }.not_to raise_error
      end

      it "logs the cleanup failure as a warning" do
        expect(Rails.logger).to receive(:warn).with(/retention cleanup failed/)
        service.execute
      end

      it "still marks BackupLog as success" do
        service.execute
        expect(BackupLog.last.status).to eq("success")
      end
    end
  end

  describe "S3 upload retry logic" do
    before { allow(Rails.logger).to receive(:warn) }

    it "retries up to MAX_UPLOAD_RETRIES times on S3 error then raises" do
      allow(mock_s3).to receive(:upload)
        .and_raise(Aws::S3::Errors::ServiceError.new(nil, "throttled"))
      allow(service).to receive(:sleep)

      expect { service.execute }.to raise_error(Aws::S3::Errors::ServiceError)
      expect(mock_s3).to have_received(:upload).at_least(described_class::MAX_UPLOAD_RETRIES).times
    end

    it "succeeds if upload recovers before hitting max retries" do
      call_count = 0
      allow(mock_s3).to receive(:upload) do
        call_count += 1
        # Fail first attempt for database category, succeed after
        raise Aws::S3::Errors::ServiceError.new(nil, "transient") if call_count == 1
        "daily/2026/04/20/file.gz"
      end
      allow(service).to receive(:sleep)

      expect { service.execute }.not_to raise_error
      expect(BackupLog.last.status).to eq("success")
    end

    it "uses exponential backoff between retries" do
      attempts = 0
      allow(mock_s3).to receive(:upload) do
        attempts += 1
        raise Aws::S3::Errors::ServiceError.new(nil, "error") if attempts <= described_class::MAX_UPLOAD_RETRIES
        "key"
      end

      expect(service).to receive(:sleep).with(2).ordered
      expect(service).to receive(:sleep).with(4).ordered
      expect { service.execute }.to raise_error(Aws::S3::Errors::ServiceError)
    end
  end

  describe "Property 3: バックアップメタデータ記録" do
    # Feature: phase-7.3-auto-backup, Property 3: バックアップメタデータ記録
    it "records started_at, completed_at, and file_size on success" do
      service.execute
      log = BackupLog.last
      expect(log.started_at).to be_present
      expect(log.completed_at).to be_present
      expect(log.file_size).to be_present
    end
  end

  describe "Property 10: バックアップ成功通知" do
    # Feature: phase-7.3-auto-backup, Property 10: バックアップ成功通知
    it "calls BackupMailer.backup_success and SlackNotifier.notify_backup_status on success" do
      expect(BackupMailer).to receive(:backup_success).with(instance_of(BackupLog))
        .and_return(double(deliver_later: nil))
      expect(SlackNotifier).to receive(:notify_backup_status).with(instance_of(BackupLog))
      service.execute
    end
  end

  describe "Property 11: バックアップ失敗通知" do
    # Feature: phase-7.3-auto-backup, Property 11: バックアップ失敗通知
    it "calls BackupMailer.backup_failed with error on failure" do
      allow(mock_db_backup).to receive(:execute).and_raise(RuntimeError, "dump error")

      expect(BackupMailer).to receive(:backup_failed)
        .with(instance_of(BackupLog), instance_of(RuntimeError))
        .and_return(double(deliver_later: nil))

      expect { service.execute }.to raise_error(RuntimeError)
    end
  end

  describe "Property 12: 通知エラー耐性" do
    # Feature: phase-7.3-auto-backup, Property 12: 通知エラー耐性
    it "does not fail the backup when notification raises an error" do
      allow(BackupMailer).to receive(:backup_success).and_raise(StandardError, "network error")
      allow(Rails.logger).to receive(:warn)
      expect { service.execute }.not_to raise_error
      expect(BackupLog.last.status).to eq("success")
    end
  end
end
