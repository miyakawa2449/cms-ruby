# frozen_string_literal: true

require "rails_helper"

RSpec.describe Security::WeeklyReportJob, type: :job do
  describe "#perform" do
    let(:service) { instance_double(Security::ReporterService) }
    let(:report) { build(:security_report, :weekly) }

    before do
      allow(Security::ReporterService).to receive(:new).and_return(service)
      allow(service).to receive(:generate_weekly_report).and_return(report)
    end

    it "calls ReporterService to generate weekly report" do
      described_class.new.perform

      expect(service).to have_received(:generate_weekly_report)
    end

    it "is queued in the default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end

    context "when an error occurs" do
      before do
        allow(service).to receive(:generate_weekly_report)
          .and_raise(StandardError, "Test error")
      end

      it "logs the error and re-raises" do
        expect(Rails.logger).to receive(:error).with(/Weekly security report failed/)

        expect {
          described_class.new.perform
        }.to raise_error(StandardError, "Test error")
      end
    end
  end
end
