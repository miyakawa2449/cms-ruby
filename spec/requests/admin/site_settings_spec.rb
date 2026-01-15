require 'rails_helper'

RSpec.describe "Admin::SiteSettings", type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe "GET /admin/site_settings" do
    it "returns http success" do
      get admin_site_settings_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "PATCH /admin/site_settings" do
    it "updates site settings" do
      patch admin_site_settings_path, params: { site_setting: { site_title: 'New Title' } }
      expect(response).to have_http_status(:redirect)
    end
  end
end
