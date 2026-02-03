# frozen_string_literal: true

require "rails_helper"

RSpec.describe Security::MonitorService do
  let(:service) { described_class.new }

  describe "#check_error_rate" do
    context "when error rate is below threshold" do
      before do
        allow(service).to receive(:count_requests).and_return(100)
        allow(service).to receive(:count_errors).and_return(3)
      end

      it "does not send alert" do
        expect(SecurityMailer).not_to receive(:high_error_rate_alert)

        service.check_error_rate
      end
    end

    context "when error rate exceeds threshold" do
      before do
        allow(service).to receive(:count_requests).and_return(100)
        allow(service).to receive(:count_errors).and_return(10)
        allow(SecurityMailer).to receive_message_chain(:high_error_rate_alert, :deliver_now)
        allow(SlackNotifier).to receive(:enabled?).and_return(false)
      end

      it "sends alert" do
        service.check_error_rate

        expect(SecurityMailer).to have_received(:high_error_rate_alert)
      end
    end

    context "when there are no requests" do
      before do
        allow(service).to receive(:count_requests).and_return(0)
      end

      it "does not send alert" do
        expect(SecurityMailer).not_to receive(:high_error_rate_alert)

        service.check_error_rate
      end
    end
  end

  describe "#check_traffic_anomaly" do
    context "when traffic is normal" do
      before do
        allow(service).to receive(:count_requests).and_return(500)
      end

      it "does not send alert" do
        expect(SecurityMailer).not_to receive(:traffic_spike_alert)

        service.check_traffic_anomaly
      end
    end

    context "when traffic exceeds threshold" do
      before do
        allow(service).to receive(:count_requests).and_return(1500)
        allow(SecurityMailer).to receive_message_chain(:traffic_spike_alert, :deliver_now)
        allow(SlackNotifier).to receive(:enabled?).and_return(false)
      end

      it "sends alert" do
        service.check_traffic_anomaly

        expect(SecurityMailer).to have_received(:traffic_spike_alert)
      end
    end
  end
end
