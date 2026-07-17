# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Admin::Dashboard", type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    host! "localhost"
    sign_in admin_user, scope: :admin_user
  end

  describe "GET /admin" do
    it "ダッシュボードが表示され統計と最近の記事が出る" do
      create(:article, :published, title: "最近の記事")
      create(:article, :draft)

      get admin_dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("最近の記事")
    end

    it "未ログインではアクセスできない" do
      sign_out admin_user

      get admin_dashboard_path

      expect(response).not_to have_http_status(:ok)
    end
  end
end
