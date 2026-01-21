require "rails_helper"

RSpec.describe ApplicationController, type: :controller do
  controller(ApplicationController) do
    def index
      render plain: "ok"
    end
  end

  describe "CSP header" do
    it "sets CSP header for non-admin paths" do
      routes.draw { get "index" => "anonymous#index" }

      get :index

      expect(response.headers["Content-Security-Policy"]).to include("default-src 'self'")
    end

    it "skips CSP header for admin paths" do
      routes.draw { get "admin/test" => "anonymous#index" }

      get :index

      expect(response.headers["Content-Security-Policy"]).to be_nil
    end
  end

  describe "#after_sign_in_path_for" do
    it "redirects admin users to dashboard" do
      admin = create(:admin_user)

      expect(controller.send(:after_sign_in_path_for, admin)).to eq(admin_dashboard_path)
    end

    it "redirects non-admin users to root" do
      user = double("User")

      expect(controller.send(:after_sign_in_path_for, user)).to eq(root_path)
    end
  end

  describe "#after_sign_out_path_for" do
    it "redirects admin scope to admin login" do
      expect(controller.send(:after_sign_out_path_for, :admin_user)).to eq(new_admin_user_session_path)
    end

    it "redirects other scopes to root" do
      expect(controller.send(:after_sign_out_path_for, :user)).to eq(root_path)
    end
  end
end
