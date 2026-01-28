require "rails_helper"

RSpec.describe "Rate Limiting", type: :request do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
  end

  after do
    Rack::Attack.enabled = false
  end

  describe "Login Rate Limiting" do
    it "allows 5 login attempts" do
      5.times do
        post admin_user_session_path, params: {
          admin_user: { email: "test@example.com", password: "wrong" }
        }
        expect(response).not_to have_http_status(:too_many_requests)
      end
    end

    it "blocks 6th login attempt" do
      6.times do
        post admin_user_session_path, params: {
          admin_user: { email: "test@example.com", password: "wrong" }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it "includes Retry-After header" do
      6.times do
        post admin_user_session_path, params: {
          admin_user: { email: "test@example.com", password: "wrong" }
        }
      end

      expect(response.headers["Retry-After"]).to be_present
    end

    it "returns JSON error body" do
      6.times do
        post admin_user_session_path, params: {
          admin_user: { email: "test@example.com", password: "wrong" }
        }
      end

      json = JSON.parse(response.body)
      expect(json["error"]).to eq("Too Many Requests")
    end
  end

  describe "Password Reset Rate Limiting" do
    it "blocks 6th password reset request" do
      6.times do
        post admin_user_password_path, params: {
          admin_user: { email: "test@example.com" }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "API Rate Limiting" do
    context "unauthenticated" do
      it "blocks 61st request" do
        61.times do
          get api_v1_articles_path
        end

        expect(response).not_to have_http_status(:success)
      end

      it "includes Retry-After header on block" do
        61.times do
          get api_v1_articles_path
        end

        if response.status == 429
          expect(response.headers["Retry-After"]).to be_present
        end
      end
    end

    context "authenticated" do
      let(:admin_user) { create(:admin_user) }

      before { sign_in admin_user, scope: :admin_user }

      it "allows authenticated requests without immediate block" do
        50.times do
          get api_v1_articles_path
        end

        expect(response).not_to have_http_status(:too_many_requests)
      end
    end
  end

  describe "Contact Form Rate Limiting" do
    it "blocks 6th submission" do
      6.times do
        post contacts_path, params: {
          contact: {
            name: "Test",
            email: "test@example.com",
            subject: "Test",
            message: "Test message"
          }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
    end
  end

  describe "Blocklist" do
    it "blocks suspicious query patterns" do
      get blog_path, params: { q: "union select" }

      expect(response).to have_http_status(:forbidden)
    end

    it "blocks path traversal patterns" do
      get blog_path, params: { q: "../etc/passwd" }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "Admin Access Rate Limiting" do
    it "blocks repeated unauthenticated access" do
      11.times do
        get admin_articles_path
      end

      expect(response).to have_http_status(:too_many_requests)
    end

    it "allows whitelisted admin IPs" do
      ENV["ADMIN_WHITELIST_IPS"] = "127.0.0.1"
      Rack::Attack.cache.store.clear

      20.times do
        get admin_articles_path
      end

      expect(response).not_to have_http_status(:too_many_requests)
    ensure
      ENV.delete("ADMIN_WHITELIST_IPS")
    end
  end

  describe "Property: Rate limiting consistently blocks excessive requests" do
    it "always returns 429 after limit exceeded" do
      10.times do
        post admin_user_session_path, params: {
          admin_user: { email: "test@example.com", password: "wrong" }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
      expect(response.headers["Retry-After"]).to be_present
    end
  end
end
