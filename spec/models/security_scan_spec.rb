# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecurityScan, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:vulnerabilities).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:scan_type) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:scanned_at) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:scan_type).with_values(brakeman: 0, bundler_audit: 1) }
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, running: 1, completed: 2, failed: 3) }
  end

  describe "scopes" do
    describe ".recent" do
      it "orders by scanned_at desc" do
        old_scan = create(:security_scan, scanned_at: 2.days.ago)
        new_scan = create(:security_scan, scanned_at: 1.day.ago)

        expect(SecurityScan.recent).to eq([ new_scan, old_scan ])
      end
    end
  end

  describe "#high_severity_count" do
    let(:scan) { create(:security_scan) }

    it "returns count of critical and high vulnerabilities" do
      create(:vulnerability, security_scan: scan, severity: :critical)
      create(:vulnerability, security_scan: scan, severity: :high)
      create(:vulnerability, security_scan: scan, severity: :medium)
      create(:vulnerability, security_scan: scan, severity: :low)

      expect(scan.high_severity_count).to eq(2)
    end
  end

  describe "#summary" do
    let(:scan) { create(:security_scan) }

    it "returns vulnerability counts by severity" do
      create(:vulnerability, security_scan: scan, severity: :critical)
      create(:vulnerability, security_scan: scan, severity: :high)
      create(:vulnerability, security_scan: scan, severity: :medium)
      create(:vulnerability, security_scan: scan, severity: :medium)
      create(:vulnerability, security_scan: scan, severity: :low)

      summary = scan.summary

      expect(summary[:critical]).to eq(1)
      expect(summary[:high]).to eq(1)
      expect(summary[:medium]).to eq(2)
      expect(summary[:low]).to eq(1)
      expect(summary[:total]).to eq(5)
    end
  end
end
