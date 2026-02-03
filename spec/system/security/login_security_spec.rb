require "rails_helper"

RSpec.describe "Login Security", type: :system do
  let(:admin_user) { create(:admin_user, password: TestCredentials.admin_password) }

  before do
    skip "Selenium not available" unless ENV["SELENIUM"] == "true"
    driven_by(:selenium_headless)
  end

  it "logs in successfully with valid credentials" do
    visit new_admin_user_session_path

    fill_in "メールアドレス", with: admin_user.email
    fill_in "パスワード", with: TestCredentials.admin_password
    click_button "ログイン"

    expect(page).to have_current_path(admin_root_path)
    expect(page).to have_content("ログインしました")
  end

  it "renders login form" do
    visit new_admin_user_session_path

    expect(page).to have_field("メールアドレス")
    expect(page).to have_field("パスワード")
  end

  it "shows error with invalid credentials" do
    visit new_admin_user_session_path

    fill_in "メールアドレス", with: admin_user.email
    fill_in "パスワード", with: "wrong"
    click_button "ログイン"

    expect(page).to have_content("メールアドレスまたはパスワードが正しくありません")
  end

  it "locks account after repeated failures" do
    visit new_admin_user_session_path

    5.times do
      fill_in "メールアドレス", with: admin_user.email
      fill_in "パスワード", with: "wrong"
      click_button "ログイン"
    end

    expect(page).to have_content("あなたのアカウントがロックされる前にもう1度お試しください")
  end
end
