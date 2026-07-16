require "rails_helper"

ActiveJob::Base.queue_adapter = :test

RSpec.describe Restore::RestoreJob, type: :job do
  let(:backup_keys) do
    {
      "database" => "daily/2026/04/20/database_file.dump.gz",
      "storage"  => "daily/2026/04/20/storage_file.tar.gz",
      "config"   => "daily/2026/04/20/config_file.tar.gz"
    }
  end
  let(:mock_service) { instance_double(RestoreService, execute: nil) }

  before do
    allow(RestoreService).to receive(:new).and_return(mock_service)
  end

  describe "#perform" do
    it "calls RestoreService with symbolized backup_keys" do
      expect(RestoreService).to receive(:new).with(
        backup_keys: {
          database: "daily/2026/04/20/database_file.dump.gz",
          storage:  "daily/2026/04/20/storage_file.tar.gz",
          config:   "daily/2026/04/20/config_file.tar.gz"
        }
      ).and_return(mock_service)
      expect(mock_service).to receive(:execute)

      described_class.new.perform(backup_keys)
    end

    it "also works with symbolized keys passed directly" do
      sym_keys = backup_keys.transform_keys(&:to_sym)
      expect(RestoreService).to receive(:new).with(backup_keys: sym_keys).and_return(mock_service)
      described_class.new.perform(sym_keys)
    end
  end

  describe "queue" do
    it "uses the :backup queue" do
      expect(described_class.queue_name).to eq("backup")
    end
  end

  describe "Property 17: 復元バックグラウンド実行" do
    # Feature: phase-7.3-auto-backup, Property 17: 復元バックグラウンド実行
    it "can be enqueued as a background job on the backup queue" do
      expect {
        described_class.perform_later(backup_keys)
      }.to have_enqueued_job(described_class)
        .with(backup_keys)
        .on_queue("backup")
    end

    it "inherits from ApplicationJob" do
      expect(described_class.superclass).to eq(ApplicationJob)
    end
  end
end
