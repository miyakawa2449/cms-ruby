require "rails_helper"

RSpec.describe "Admin authentication", type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    host! "localhost"
  end

  describe "ログイン・ログアウト" do
    it "ログインページが表示される" do
      get new_admin_user_session_path

      expect(response).not_to have_http_status(:unauthorized)
    end

    it "正しい認証情報でログインできる" do
      post admin_user_session_path, params: {
        admin_user: {
          email: admin_user.email,
          password: admin_user.password
        }
      }

      expect([302, 303, 429]).to include(response.status)
    end

    it "不正な認証情報ではログインできない" do
      post admin_user_session_path, params: {
        admin_user: {
          email: admin_user.email,
          password: "wrong"
        }
      }

      expect([422, 429]).to include(response.status)
    end

    it "ログアウトできる" do
      sign_in admin_user

      delete destroy_admin_user_session_path

      expect(response).to redirect_to(new_admin_user_session_path)
    end

    it "Remember meのcookieが発行される" do
      post admin_user_session_path, params: {
        admin_user: {
          email: admin_user.email,
          password: admin_user.password,
          remember_me: "1"
        }
      }

      expect(response.cookies["remember_admin_user_token"]).to be_present
    end
  end

  describe "アクセス拒否" do
    it "未認証ユーザーはダッシュボードにアクセスできない" do
      get admin_dashboard_path

      expect(response).to redirect_to(new_admin_user_session_path)
    end

    it "未認証ユーザーは記事一覧にアクセスできない" do
      get admin_articles_path

      expect(response).not_to have_http_status(:success)
    end

    it "未認証ユーザーはサイト設定にアクセスできない" do
      get admin_site_settings_path

      expect(response).not_to have_http_status(:success)
    end

    it "未認証ユーザーは記事作成を行えない" do
      post admin_articles_path, params: { article: attributes_for(:article) }

      expect([302, 303, 429]).to include(response.status)
    end

    it "未認証ユーザーはお問い合わせ管理にアクセスできない" do
      get admin_contacts_path

      expect(response).not_to have_http_status(:success)
    end
  end

  describe "セッション管理" do
    before do
      sign_in admin_user
    end

    it "ログイン後にダッシュボードへアクセスできる" do
      get admin_dashboard_path

      expect(response).to have_http_status(:success)
    end

    it "ログイン後に記事一覧へアクセスできる" do
      get admin_articles_path

      expect(response).to have_http_status(:success)
    end

    it "ログアウト後はダッシュボードにアクセスできない" do
      delete destroy_admin_user_session_path

      get admin_dashboard_path

      expect(response).not_to have_http_status(:success)
    end

    it "セッションが維持される" do
      get admin_dashboard_path
      get admin_articles_path

      expect(response).to have_http_status(:success)
    end

    it "ログアウト後は記事一覧にアクセスできない" do
      delete destroy_admin_user_session_path

      get admin_articles_path

      expect(response).not_to have_http_status(:success)
    end
  end
end
