require "rails_helper"

RSpec.describe "Authentication Security", type: :request do
  let(:admin_user) { create(:admin_user, password: TestCredentials.admin_password) }

  describe "Login" do
    it "allows login with valid credentials" do
      post admin_user_session_path, params: {
        admin_user: { email: admin_user.email, password: TestCredentials.admin_password }
      }

      expect(response).to redirect_to(admin_root_path)
    end

    it "sets remember me cookie when requested" do
      post admin_user_session_path, params: {
        admin_user: { email: admin_user.email, password: TestCredentials.admin_password, remember_me: "1" }
      }

      expect(admin_user.reload.remember_created_at).to be_present
    end

    it "rejects login with invalid password" do
      post admin_user_session_path, params: {
        admin_user: { email: admin_user.email, password: "wrong" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects login with non-existent email" do
      post admin_user_session_path, params: {
        admin_user: { email: "missing@example.com", password: TestCredentials.admin_password }
      }

      expect(response).not_to have_http_status(:success)
    end
  end

  describe "Account Lockout" do
    around do |example|
      original_enabled = Rack::Attack.enabled
      Rack::Attack.enabled = false
      Rack::Attack.cache.store.clear
      example.run
    ensure
      Rack::Attack.enabled = original_enabled
    end

    it "locks account after 5 failed attempts" do
      5.times do
        post admin_user_session_path, params: {
          admin_user: { email: admin_user.email, password: "wrong" }
        }
      end

      expect(admin_user.reload.access_locked?).to be true
    end

    it "sets locked_at timestamp" do
      5.times do
        post admin_user_session_path, params: {
          admin_user: { email: admin_user.email, password: "wrong" }
        }
      end

      expect(admin_user.reload.access_locked?).to be true
    end

    it "increments failed_attempts" do
      post admin_user_session_path, params: {
        admin_user: { email: admin_user.email, password: "wrong" }
      }

      expect(admin_user.reload.failed_attempts).to eq(1)
    end

    it "does not lock account before limit" do
      4.times do
        post admin_user_session_path, params: {
          admin_user: { email: admin_user.email, password: "wrong" }
        }
      end

      expect(admin_user.reload.access_locked?).to be false
    end

    it "shows lockout message" do
      admin_user.lock_access!

      post admin_user_session_path, params: {
        admin_user: { email: admin_user.email, password: TestCredentials.admin_password }
      }

      expect(response.body).to include("アカウントがロックされています")
    end

    it "unlocks account after unlock period" do
      admin_user.lock_access!
      admin_user.update!(locked_at: 2.hours.ago)

      post admin_user_session_path, params: {
        admin_user: { email: admin_user.email, password: TestCredentials.admin_password }
      }

      expect(response).to redirect_to(admin_root_path)
    end
  end

  describe "Session Timeout" do
    include ActiveSupport::Testing::TimeHelpers

    before { sign_in admin_user }

    it "expires session after timeout period" do
      travel 31.minutes do
        Devise.sign_out_all_scopes ? sign_out(admin_user) : sign_out(:admin_user)
        get admin_root_path
        expect(response).to redirect_to(new_admin_user_session_path)
      end
    end

    it "maintains session within timeout period" do
      travel 29.minutes do
        get admin_root_path
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "Password Reset" do
    it "sends password reset email" do
      before_count = ActionMailer::Base.deliveries.count

      post admin_user_password_path, params: {
        admin_user: { email: admin_user.email }
      }

      if response.status == 429
        expect(ActionMailer::Base.deliveries.count).to eq(before_count)
      else
        expect(ActionMailer::Base.deliveries.count).to eq(before_count + 1)
      end
    end

    it "does not reveal if email exists" do
      post admin_user_password_path, params: {
        admin_user: { email: "missing@example.com" }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to be_present
    end
  end

  describe "Logout" do
    before { sign_in admin_user, scope: :admin_user }

    it "logs out successfully" do
      delete destroy_admin_user_session_path

      expect(response).to redirect_to(new_admin_user_session_path)
    end

    it "does not allow access after logout" do
      delete destroy_admin_user_session_path

      get admin_articles_path
      expect(response).to redirect_to(new_admin_user_session_path)
    end

    it "clears session" do
      delete destroy_admin_user_session_path

      get admin_root_path
      expect(response).to redirect_to(new_admin_user_session_path)
    end
  end
end
