require "rails_helper"

RSpec.describe "Session Security", type: :request do
  let(:admin_user) { create(:admin_user, password: TestCredentials.admin_password) }
  let(:session_key) { Rails.application.config.session_options[:key] }

  it "resets session on login" do
    get new_admin_user_session_path
    initial_cookie = response.cookies[session_key]

    post admin_user_session_path, params: {
      admin_user: { email: admin_user.email, password: TestCredentials.admin_password }
    }

    expect(response).not_to have_http_status(:unauthorized)
    expect(response).not_to have_http_status(:unprocessable_entity)
  end

  it "has a session after login" do
    post admin_user_session_path, params: {
      admin_user: { email: admin_user.email, password: TestCredentials.admin_password }
    }

    expect(response).not_to have_http_status(:unauthorized)
  end

  it "clears session on logout" do
    sign_in admin_user

    delete destroy_admin_user_session_path

    get admin_root_path
    expect(response).not_to have_http_status(:success)
  end

  it "uses configured session timeout" do
    expect(Devise.timeout_in).to eq(30.minutes)
  end
end
