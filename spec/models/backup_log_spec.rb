# frozen_string_literal: true

require "rails_helper"

RSpec.describe BackupLog, type: :model do
  describe "validations" do
    it { should validate_presence_of(:backup_type) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:started_at) }
  end

  describe "enums" do
    it "defines backup_type enum" do
      expect(BackupLog.backup_types).to eq("daily" => 0, "weekly" => 1, "monthly" => 2, "restore" => 3)
    end

    it "defines status enum" do
      expect(BackupLog.statuses).to eq("in_progress" => 0, "success" => 1, "failed" => 2)
    end
  end

  describe "scopes" do
    describe ".recent" do
      it "returns logs ordered by started_at descending" do
        old_log = create(:backup_log, started_at: 2.hours.ago)
        new_log = create(:backup_log, started_at: 1.hour.ago)
        expect(BackupLog.recent.first).to eq(new_log)
        expect(BackupLog.recent.last).to eq(old_log)
      end
    end

    describe ".by_type" do
      it "filters by backup type" do
        daily_log = create(:backup_log, backup_type: :daily)
        weekly_log = create(:backup_log, backup_type: :weekly)
        expect(BackupLog.by_type(:daily)).to include(daily_log)
        expect(BackupLog.by_type(:daily)).not_to include(weekly_log)
      end
    end

    describe "enum scopes (.success, .failed, .in_progress)" do
      it "returns successful logs" do
        success_log = create(:backup_log, status: :success)
        expect(BackupLog.success).to include(success_log)
      end

      it "returns failed logs" do
        failed_log = create(:backup_log, status: :failed)
        expect(BackupLog.failed).to include(failed_log)
      end
    end
  end

  describe "#duration" do
    context "when completed_at is set" do
      it "returns elapsed seconds" do
        log = build(:backup_log, started_at: 10.minutes.ago, completed_at: Time.current)
        expect(log.duration).to be_within(5).of(600)
      end
    end

    context "when completed_at is nil" do
      it "returns nil" do
        log = build(:backup_log, completed_at: nil)
        expect(log.duration).to be_nil
      end
    end
  end

  describe "#file_size_mb" do
    context "when file_size is set" do
      it "returns size in MB rounded to 2 decimal places" do
        log = build(:backup_log, file_size: 10_485_760)  # 10MB
        expect(log.file_size_mb).to eq(10.0)
      end

      it "rounds to 2 decimal places" do
        log = build(:backup_log, file_size: 1_000_000)
        expect(log.file_size_mb).to eq(0.95)
      end
    end

    context "when file_size is nil" do
      it "returns nil" do
        log = build(:backup_log, file_size: nil)
        expect(log.file_size_mb).to be_nil
      end
    end
  end
end
