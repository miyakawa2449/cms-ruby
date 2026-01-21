require "rails_helper"

RSpec.describe "画像・メディアフロー", type: :system do
  let(:admin_user) { create(:admin_user) }

  before do
    skip "Selenium not available" unless ENV["SELENIUM"] == "true"
    driven_by(:selenium_headless)
    login_as(admin_user, scope: :admin_user)
  end

  it "メディアライブラリページが表示される" do
    visit admin_media_path

    expect(page).to have_content("メディアライブラリ")
  end

  it "一覧にメディアが表示される" do
    blob = create(:active_storage_blob, filename: "test_document.pdf", content_type: "application/pdf")
    create(:media_metadata, blob: blob)

    visit admin_media_path

    expect(page).to have_content("test_document.pdf")
  end

  it "アップロードモーダルが開く" do
    visit admin_media_path

    click_button "アップロード"

    expect(page).to have_content("画像アップロード")
  end

  it "画像をアップロードして一覧に表示できる" do
    visit admin_media_path

    click_button "アップロード"

    find("input[type='file']", visible: false).attach_file(
      Rails.root.join("spec/fixtures/files/test_image.jpg")
    )
    find("[data-media-upload-target='submitBtn']").click

    expect(page).to have_content("test_image.jpg", wait: 10)
  end

  it "メディア詳細ページが表示される" do
    media = create(:media_metadata)

    visit admin_medium_path(media)

    expect(page).to have_content(media.filename)
  end
end
