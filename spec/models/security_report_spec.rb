# frozen_string_literal: true

require "rails_helper"

RSpec.describe SecurityReport, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:report_type) }
    it { is_expected.to validate_presence_of(:period_start) }
    it { is_expected.to validate_presence_of(:period_end) }
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:report_type).with_values(weekly: 0, monthly: 1, custom: 2) }
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, generating: 1, completed: 2, failed: 3) }
  end

  describe "scopes" do
    describe ".recent" do
      it "orders by generated_at desc" do
        old_report = create(:security_report, generated_at: 2.days.ago)
        new_report = create(:security_report, generated_at: 1.day.ago)

        expect(SecurityReport.recent).to eq([ new_report, old_report ])
      end
    end
  end

  describe "#pdf_filename" do
    let(:report) do
      create(:security_report,
        period_start: Date.new(2026, 1, 1),
        period_end: Date.new(2026, 1, 7))
    end

    it "returns formatted filename" do
      expect(report.pdf_filename).to eq("security-report-2026-01-01-2026-01-07.pdf")
    end
  end
end
