require "rails_helper"

RSpec.describe AdminPath::RotationJob, type: :job do
  let!(:admin_user) { create(:admin_user) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ADMIN_PATH_ROTATION_ENABLED", "false").and_return("true")
    allow(ENV).to receive(:fetch).with("ADMIN_PATH_ROTATION_FREQUENCY", "monthly").and_return("monthly")
    allow(ENV).to receive(:fetch).with("ADMIN_PATH", anything).and_return("old-admin-path")
    allow(ENV).to receive(:[]=)

    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(Rails.root.join(".env.production")).and_return(false)
    allow(Rails.application).to receive(:reload_routes!)

    mailer_double = double(deliver_later: true)
    allow(AdminPathMailer).to receive(:path_changed).and_return(mailer_double)
    allow(SlackNotifier).to receive(:notify_admin_path_changed).and_return(true)
  end

  describe "#perform" do
    context "when rotation is enabled and due" do
      before do
        create(:admin_path_history, created_at: 2.months.ago)
      end

      it "performs rotation" do
        expect {
          described_class.new.perform
        }.to change(AdminPathHistory, :count).by(1)
      end

      it "creates auto_rotation type history" do
        described_class.new.perform
        expect(AdminPathHistory.last.change_type).to eq("auto_rotation")
      end
    end

    context "when rotation is not due" do
      before do
        create(:admin_path_history, created_at: 1.day.ago)
      end

      it "does not perform rotation" do
        expect {
          described_class.new.perform
        }.not_to change(AdminPathHistory, :count)
      end
    end

    context "when rotation is disabled" do
      before do
        allow(ENV).to receive(:fetch).with("ADMIN_PATH_ROTATION_ENABLED", "false").and_return("false")
      end

      it "does not perform rotation" do
        expect {
          described_class.new.perform
        }.not_to change(AdminPathHistory, :count)
      end
    end
  end
end
