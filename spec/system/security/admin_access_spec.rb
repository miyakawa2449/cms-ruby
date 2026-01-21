require "rails_helper"

RSpec.describe "Admin Access Security", type: :system do
  let(:admin_user) { create(:admin_user, password: "password123") }

  before do
    skip "Selenium not available" unless ENV["SELENIUM"] == "true"
    driven_by(:selenium_headless)
  end

  it "redirects unauthenticated users to login" do
    visit admin_root_path

    expect(page).to have_current_path(new_admin_user_session_path)
  end

  it "redirects unauthenticated users from admin articles" do
    visit admin_articles_path

    expect(page).to have_current_path(new_admin_user_session_path)
  end

  it "allows authenticated users to access admin dashboard" do
    login_as(admin_user, scope: :admin_user)
    visit admin_root_path

    expect(page).to have_content("ダッシュボード")
  end
end
