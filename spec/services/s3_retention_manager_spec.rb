require "rails_helper"

RSpec.describe S3RetentionManager do
  let(:mock_s3) { instance_double(S3Service) }

  before do
    allow(S3Service).to receive(:new).and_return(mock_s3)
  end

  def backup_entry(key:, age_days:)
    { key: key, size: 1024, last_modified: age_days.days.ago, etag: '"abc"' }
  end

  describe "RETENTION_DAYS" do
    it "defines 7 days for daily" do
      expect(described_class::RETENTION_DAYS["daily"]).to eq(7)
    end

    it "defines 28 days for weekly" do
      expect(described_class::RETENTION_DAYS["weekly"]).to eq(28)
    end

    it "defines 365 days for monthly" do
      expect(described_class::RETENTION_DAYS["monthly"]).to eq(365)
    end
  end

  describe "#cleanup" do
    context "with daily backups (7-day retention)" do
      let(:manager) { described_class.new("daily") }

      let(:old_backup) { backup_entry(key: "daily/2026/04/12/database_old.dump.gz", age_days: 8) }
      let(:fresh_backup) { backup_entry(key: "daily/2026/04/19/database_new.dump.gz", age_days: 1) }

      before do
        allow(mock_s3).to receive(:list_backups).with(backup_type: "daily")
          .and_return([ old_backup, fresh_backup ])
        allow(mock_s3).to receive(:delete)
      end

      it "deletes backups older than retention period" do
        expect(mock_s3).to receive(:delete).with(object_key: old_backup[:key])
        manager.cleanup
      end

      it "does not delete backups within retention period" do
        expect(mock_s3).not_to receive(:delete).with(object_key: fresh_backup[:key])
        manager.cleanup
      end

      it "logs deleted key" do
        expect(Rails.logger).to receive(:info).with(/deleted key=#{Regexp.escape(old_backup[:key])}/)
        allow(Rails.logger).to receive(:info)
        manager.cleanup
      end

      it "logs cleanup summary" do
        allow(mock_s3).to receive(:delete)
        expect(Rails.logger).to receive(:info).with(/cleanup completed.*deleted=1/)
        allow(Rails.logger).to receive(:info)
        manager.cleanup
      end
    end

    context "with weekly backups (28-day retention)" do
      let(:manager) { described_class.new("weekly") }

      it "deletes backups older than 28 days" do
        old = backup_entry(key: "weekly/old.tar.gz", age_days: 29)
        recent = backup_entry(key: "weekly/recent.tar.gz", age_days: 27)
        allow(mock_s3).to receive(:list_backups).with(backup_type: "weekly")
          .and_return([ old, recent ])
        allow(mock_s3).to receive(:delete)

        expect(mock_s3).to receive(:delete).with(object_key: old[:key])
        expect(mock_s3).not_to receive(:delete).with(object_key: recent[:key])
        manager.cleanup
      end
    end

    context "with monthly backups (365-day retention)" do
      let(:manager) { described_class.new("monthly") }

      it "deletes backups older than 365 days" do
        old = backup_entry(key: "monthly/old.tar.gz", age_days: 366)
        recent = backup_entry(key: "monthly/recent.tar.gz", age_days: 364)
        allow(mock_s3).to receive(:list_backups).with(backup_type: "monthly")
          .and_return([ old, recent ])
        allow(mock_s3).to receive(:delete)

        expect(mock_s3).to receive(:delete).with(object_key: old[:key])
        expect(mock_s3).not_to receive(:delete).with(object_key: recent[:key])
        manager.cleanup
      end
    end

    context "when nothing is old enough to delete" do
      let(:manager) { described_class.new("daily") }

      it "does not call delete" do
        fresh = backup_entry(key: "daily/fresh.dump.gz", age_days: 1)
        allow(mock_s3).to receive(:list_backups).with(backup_type: "daily").and_return([ fresh ])

        expect(mock_s3).not_to receive(:delete)
        manager.cleanup
      end

      it "logs deleted=0 in summary" do
        allow(mock_s3).to receive(:list_backups).with(backup_type: "daily").and_return([])
        expect(Rails.logger).to receive(:info).with(/deleted=0/)
        allow(Rails.logger).to receive(:info)
        manager.cleanup
      end
    end

    context "when a deletion fails" do
      let(:manager) { described_class.new("daily") }

      let(:failing_backup) { backup_entry(key: "daily/fail.dump.gz", age_days: 10) }
      let(:other_backup) { backup_entry(key: "daily/other.dump.gz", age_days: 12) }

      before do
        allow(mock_s3).to receive(:list_backups).with(backup_type: "daily")
          .and_return([ failing_backup, other_backup ])
      end

      it "logs a warning for the failed deletion" do
        allow(mock_s3).to receive(:delete).with(object_key: failing_backup[:key])
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "Access Denied"))
        allow(mock_s3).to receive(:delete).with(object_key: other_backup[:key])

        expect(Rails.logger).to receive(:warn).with(/failed to delete.*#{Regexp.escape(failing_backup[:key])}/)
        allow(Rails.logger).to receive(:info)
        manager.cleanup
      end

      it "continues deleting remaining backups after a failure" do
        allow(mock_s3).to receive(:delete).with(object_key: failing_backup[:key])
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "Access Denied"))
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        expect(mock_s3).to receive(:delete).with(object_key: other_backup[:key])
        manager.cleanup
      end

      it "does not raise an error when deletion fails" do
        allow(mock_s3).to receive(:delete)
          .and_raise(Aws::S3::Errors::ServiceError.new(nil, "Access Denied"))
        allow(Rails.logger).to receive(:warn)
        allow(Rails.logger).to receive(:info)

        expect { manager.cleanup }.not_to raise_error
      end
    end

    context "when backup_type is unknown" do
      let(:manager) { described_class.new("unknown_type") }

      it "logs a warning and skips cleanup" do
        expect(mock_s3).not_to receive(:list_backups)
        expect(Rails.logger).to receive(:warn).with(/unknown backup_type/)
        manager.cleanup
      end
    end
  end

  describe "Property 8: バックアップ保持期間" do
    # Feature: phase-7.3-auto-backup, Property 8: バックアップ保持期間
    it "deletes only backups exceeding the defined retention period for each type" do
      {
        "daily" => 7,
        "weekly" => 28,
        "monthly" => 365
      }.each do |type, days|
        manager = described_class.new(type)

        boundary_old = backup_entry(key: "#{type}/old.gz", age_days: days + 1)
        boundary_new = backup_entry(key: "#{type}/new.gz", age_days: days - 1)

        allow(mock_s3).to receive(:list_backups).with(backup_type: type)
          .and_return([ boundary_old, boundary_new ])
        allow(mock_s3).to receive(:delete)
        allow(Rails.logger).to receive(:info)

        expect(mock_s3).to receive(:delete).with(object_key: boundary_old[:key])
        expect(mock_s3).not_to receive(:delete).with(object_key: boundary_new[:key])
        manager.cleanup
      end
    end
  end

  describe "Property 9: 世代管理エラー耐性" do
    # Feature: phase-7.3-auto-backup, Property 9: 世代管理エラー耐性
    let(:manager) { described_class.new("daily") }

    it "continues processing remaining backups even when individual deletions fail" do
      backups = (1..5).map do |i|
        backup_entry(key: "daily/backup_#{i}.gz", age_days: 10 + i)
      end
      allow(mock_s3).to receive(:list_backups).with(backup_type: "daily").and_return(backups)

      # Every other deletion fails
      call_count = 0
      allow(mock_s3).to receive(:delete) do
        call_count += 1
        raise Aws::S3::Errors::ServiceError.new(nil, "Error") if call_count.odd?
      end
      allow(Rails.logger).to receive(:warn)
      allow(Rails.logger).to receive(:info)

      expect { manager.cleanup }.not_to raise_error
      expect(call_count).to eq(5)
    end
  end
end
