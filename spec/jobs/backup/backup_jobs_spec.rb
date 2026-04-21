require "rails_helper"

ActiveJob::Base.queue_adapter = :test

RSpec.shared_examples "a backup job" do |job_class, backup_type|
  let(:mock_service) { instance_double(BackupService, execute: nil) }

  before do
    allow(BackupService).to receive(:new).with(backup_type: backup_type).and_return(mock_service)
  end

  describe "#perform" do
    it "calls BackupService with backup_type: #{backup_type}" do
      expect(BackupService).to receive(:new).with(backup_type: backup_type).and_return(mock_service)
      expect(mock_service).to receive(:execute)
      job_class.new.perform
    end
  end

  describe "queue" do
    it "uses the :backup queue" do
      expect(job_class.queue_name).to eq("backup")
    end
  end

  describe "enqueueing" do
    it "can be enqueued" do
      expect { job_class.perform_later }.to have_enqueued_job(job_class).on_queue("backup")
    end
  end
end

RSpec.describe Backup::DailyBackupJob, type: :job do
  include_examples "a backup job", described_class, "daily"
end

RSpec.describe Backup::WeeklyBackupJob, type: :job do
  include_examples "a backup job", described_class, "weekly"
end

RSpec.describe Backup::MonthlyBackupJob, type: :job do
  include_examples "a backup job", described_class, "monthly"
end
