require "rails_helper"

RSpec.describe AdminPath::Updater do
  let(:admin_user) { create(:admin_user) }
  let(:new_path) { "new-admin-path-2026" }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ADMIN_PATH", anything).and_return("old-admin-path")
    allow(ENV).to receive(:[]=)

    # Stub file operations
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with(Rails.root.join(".env.production")).and_return(false)

    # Stub route reload
    allow(Rails.application).to receive(:reload_routes!)

    # Stub notifications
    mailer_double = double(deliver_later: true)
    allow(AdminPathMailer).to receive(:path_changed).and_return(mailer_double)
    allow(SlackNotifier).to receive(:notify_admin_path_changed).and_return(true)
  end

  describe "#call" do
    context "with valid parameters" do
      it "updates admin path successfully" do
        result = described_class.new(
          admin_user: admin_user,
          new_path: new_path,
          change_type: :manual
        ).call

        expect(result[:success]).to be true
        expect(result[:new_path]).to eq(new_path)
      end

      it "creates history record" do
        expect {
          described_class.new(
            admin_user: admin_user,
            new_path: new_path,
            change_type: :manual
          ).call
        }.to change(AdminPathHistory, :count).by(1)
      end

      it "sends notifications" do
        described_class.new(
          admin_user: admin_user,
          new_path: new_path,
          change_type: :manual
        ).call

        expect(AdminPathMailer).to have_received(:path_changed)
        expect(SlackNotifier).to have_received(:notify_admin_path_changed)
      end

      it "reloads routes after update" do
        described_class.new(
          admin_user: admin_user,
          new_path: new_path,
          change_type: :manual
        ).call

        expect(Rails.application).to have_received(:reload_routes!)
      end
    end

    context "with invalid parameters" do
      it "returns error for reserved path" do
        result = described_class.new(
          admin_user: admin_user,
          new_path: "admin",
          change_type: :manual
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("reserved")
      end

      it "returns error for reserved path with mixed case" do
        result = described_class.new(
          admin_user: admin_user,
          new_path: "Admin",
          change_type: :manual
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("reserved")
      end

      it "returns error for invalid format" do
        result = described_class.new(
          admin_user: admin_user,
          new_path: "Admin_Path!",
          change_type: :manual
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("alphanumeric")
      end

      it "returns error for consecutive hyphens" do
        result = described_class.new(
          admin_user: admin_user,
          new_path: "admin--path",
          change_type: :manual
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("hyphens")
      end

      it "returns error for too long path" do
        result = described_class.new(
          admin_user: admin_user,
          new_path: "a" * 65,
          change_type: :manual
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("too long")
      end

      it "returns error for empty path" do
        result = described_class.new(
          admin_user: admin_user,
          new_path: "",
          change_type: :manual
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("empty")
      end

      it "returns error for same path" do
        result = described_class.new(
          admin_user: admin_user,
          new_path: "old-admin-path",
          change_type: :manual
        ).call

        expect(result[:success]).to be false
        expect(result[:error]).to include("same")
      end
    end
  end
end
