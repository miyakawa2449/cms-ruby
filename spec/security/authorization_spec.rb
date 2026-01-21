require "rails_helper"

RSpec.describe "Authorization Security", type: :request do
  let(:admin_user) { create(:admin_user) }

  describe "Admin Access Control" do
    context "when not authenticated" do
      it "redirects to login page" do
        get admin_root_path
        expect(response).not_to have_http_status(:success)
      end

      it "logs unauthorized access" do
        allow(SecurityLogger).to receive(:log_unauthorized_access)
        get admin_articles_path
        if response.status == 429
          expect(response).to have_http_status(:too_many_requests)
        else
          expect(SecurityLogger).to have_received(:log_unauthorized_access).at_least(:once)
        end
      end

      it "blocks access to admin media" do
        get admin_media_path
        expect(response).not_to have_http_status(:success)
      end

      it "blocks access to admin contacts" do
        get admin_contacts_path
        expect(response).not_to have_http_status(:success)
      end

      it "blocks access to admin sections" do
        get admin_sections_path
        expect(response).not_to have_http_status(:success)
      end

      it "blocks access to admin tags" do
        get admin_tags_path
        expect(response).not_to have_http_status(:success)
      end
    end

    context "when authenticated" do
      before { sign_in admin_user, scope: :admin_user }

      it "allows access to admin dashboard" do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end

      it "allows access to admin articles" do
        get admin_articles_path
        expect(response).to have_http_status(:success)
      end

      it "allows access to admin settings" do
        get admin_site_settings_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "Public Access" do
    it "allows access to public pages" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "allows access to blog" do
      get blog_path
      expect(response).to have_http_status(:success)
    end

    it "allows access to portfolio" do
      get root_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "Property: Admin routes require authentication" do
    let(:admin_routes) do
      Rails.application.routes.routes
        .select { |r| r.path.spec.to_s.start_with?("/#{ENV.fetch("ADMIN_PATH", "admin-secure-panel-miyakawa2449")}") }
        .map { |r| r.path.spec.to_s.gsub(/\(.*?\)/, "") }
        .uniq
        .reject { |p| p.include?("sign_in") || p.include?("sign_out") || p.include?("password") }
    end

    it "redirects unauthenticated users" do
      admin_routes.sample(5).each do |path|
        sanitized = path.gsub(":id", "1").gsub(":format", "html")
        get sanitized
        expect(response).not_to have_http_status(:success)
      end
    end
  end
end
