# frozen_string_literal: true

require "rails_helper"

RSpec.describe BackupMailer, type: :mailer do
  let(:backup_log) do
    double("BackupLog",
      id: 1,
      backup_type: "daily",
      status: "success",
      file_size: 1024 * 1024 * 50,
      s3_key: "daily/backup_20260123_030000.zip",
      error_message: nil,
      started_at: 1.hour.ago,
      completed_at: Time.current,
      created_at: 1.hour.ago
    )
  end

  describe "#backup_success" do
    let(:mail) { described_class.backup_success(backup_log) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Backup] Daily backup completed successfully")
      expect(mail.to).to include(ENV.fetch("ADMIN_EMAIL", "admin@example.test"))
    end

    it "renders the body with backup details" do
      expect(body).to include("daily")
      expect(body).to include("50.0 MB")
      expect(body).to include("daily/backup_20260123_030000.zip")
    end
  end

  describe "#backup_failed" do
    let(:failed_log) do
      double("BackupLog",
        id: 2,
        backup_type: "weekly",
        status: "failed",
        file_size: nil,
        s3_key: nil,
        error_message: "Connection timeout",
        started_at: 1.hour.ago,
        completed_at: nil,
        created_at: 1.hour.ago
      )
    end
    let(:mail) { described_class.backup_failed(failed_log) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Urgent] Weekly backup failed")
      expect(mail.to).to include(ENV.fetch("ADMIN_EMAIL", "admin@example.test"))
    end

    it "renders the body with error details" do
      expect(body).to include("weekly")
      expect(body).to include("Connection timeout")
    end
  end

  describe "#restore_success" do
    let(:mail) { described_class.restore_success(backup_log) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Backup] Restore completed successfully")
    end

    it "renders the body with restore details" do
      expect(body).to include("daily")
      expect(body).to include(backup_log.s3_key)
    end
  end

  describe "#restore_failed" do
    let(:error) { StandardError.new("Database restore failed") }
    let(:mail) { described_class.restore_failed(backup_log, error) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Urgent] Restore failed")
    end

    it "renders the body with error details" do
      expect(body).to include("Database restore failed")
    end
  end
end
