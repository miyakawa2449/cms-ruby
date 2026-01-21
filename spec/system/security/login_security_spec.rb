require "rails_helper"

RSpec.describe "Login Security", type: :system do
  let(:admin_user) { create(:admin_user, password: TestCredentials.admin_password) }

  before do
    skip "Selenium not available" unless ENV["SELENIUM"] == "true"
    driven_by(:selenium_headless)
  end

  it "logs in successfully with valid credentials" do
    visit new_admin_user_session_path

    fill_in "Email", with: admin_user.email
    fill_in "Password", with: TestCredentials.admin_password
    click_button "ログイン"

    expect(page).to have_current_path(admin_root_path)
    expect(page).to have_content("ログインしました")
  end

  it "renders login form" do
    visit new_admin_user_session_path

    expect(page).to have_field("Email")
    expect(page).to have_field("Password")
  end

  it "shows error with invalid credentials" do
    visit new_admin_user_session_path

    fill_in "Email", with: admin_user.email
    fill_in "Password", with: "wrong"
    click_button "ログイン"

    expect(page).to have_content("メールアドレスまたはパスワードが違います")
  end

  it "locks account after repeated failures" do
    visit new_admin_user_session_path

    5.times do
      fill_in "Email", with: admin_user.email
      fill_in "Password", with: "wrong"
      click_button "ログイン"
    end

    expect(page).to have_content("アカウントがロックされています")
  end
end
