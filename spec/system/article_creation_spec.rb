require "rails_helper"

RSpec.describe "記事作成フロー", type: :system do
  let(:admin_user) { create(:admin_user) }

  before do
    skip "Selenium not available" unless ENV["SELENIUM"] == "true"
    driven_by(:selenium_headless)
    login_as(admin_user, scope: :admin_user)
  end

  def ai_controller_script
    "window.Stimulus.getControllerForElementAndIdentifier(" \
      "document.querySelector('[data-controller=\"ai-assistant\"]'), " \
      "'ai-assistant')"
  end

  it "記事作成ページが表示される" do
    visit new_admin_article_path

    expect(page).to have_content("記事情報")
  end

  it "必須項目で記事を作成できる" do
    visit new_admin_article_path

    fill_in "タイトル", with: "システムテスト記事"
    fill_in "URL スラッグ", with: "system-test-article"
    fill_in "article_content", with: "本文テキスト"

    click_button "作成する"

    expect(page).to have_content("記事を作成しました")
    expect(page).to have_content("システムテスト記事")
  end

  it "バリデーションエラーが表示される" do
    visit new_admin_article_path

    click_button "作成する"

    expect(page).to have_content("エラーが発生しました")
  end

  it "編集画面でAIボタンが表示される" do
    article = create(:article, admin_user: admin_user)

    visit edit_admin_article_path(article)

    expect(page).to have_css("[data-ai-assistant-target='titleButton']")
  end

  it "タイトル提案が表示される" do
    article = create(:article, admin_user: admin_user, content: "AI本文")

    visit edit_admin_article_path(article)
    page.execute_script(<<~JS)
      #{ai_controller_script}.displayTitleResults({
        descriptive_titles: [ { title: "わかりやすいタイトル1", reason: "理由1" } ],
        engaging_titles: [ { title: "魅力的タイトル1", reason: "理由2" } ],
        current_title: "#{article.title}"
      });
    JS

    expect(page).to have_content("わかりやすいタイトル1", wait: 10)
  end

  it "提案タイトルを適用できる" do
    article = create(:article, admin_user: admin_user, content: "AI本文")

    visit edit_admin_article_path(article)
    page.execute_script(<<~JS)
      #{ai_controller_script}.displayTitleResults({
        descriptive_titles: [ { title: "採用タイトル", reason: "理由" } ],
        engaging_titles: [],
        current_title: "#{article.title}"
      });
    JS

    expect(page).to have_content("採用タイトル", wait: 10)
    find("[data-action='click->ai-assistant#applyTitle']", match: :first).click

    expect(find_field("タイトル").value).to eq("採用タイトル")
  end

  it "要約生成が表示される" do
    article = create(:article, admin_user: admin_user, content: "AI本文")

    visit edit_admin_article_path(article)
    page.execute_script(<<~JS)
      #{ai_controller_script}.displaySummaryResults([ { text: "テスト要約1", length: 80 } ]);
    JS

    expect(page).to have_content("テスト要約1", wait: 10)
  end

  it "スラッグ候補が表示される" do
    article = create(:article, admin_user: admin_user, content: "AI本文")

    visit edit_admin_article_path(article)
    page.execute_script(<<~JS)
      #{ai_controller_script}.displaySlugResults([ { slug: "test-article-slug", seo_score: 95 } ]);
    JS

    expect(page).to have_content("test-article-slug", wait: 10)
  end

  it "タグ提案が表示される" do
    article = create(:article, admin_user: admin_user, content: "AI本文")

    visit edit_admin_article_path(article)
    page.execute_script(<<~JS)
      #{ai_controller_script}.displayTagResults(
        [ { name: "Ruby", confidence: 0.95, existing: true } ],
        []
      );
    JS

    expect(page).to have_content("Ruby", wait: 10)
  end

  it "SEOメタの生成結果が表示される" do
    article = create(:article, admin_user: admin_user, content: "AI本文")

    visit edit_admin_article_path(article)
    page.execute_script(<<~JS)
      #{ai_controller_script}.displaySeoResults({
        meta_description: "テスト用のメタディスクリプションです。",
        meta_keywords: "Ruby, Rails",
        og_title: "テスト記事のOGタイトル",
        og_description: "OG用の説明文です。"
      });
    JS

    expect(page).to have_content("メタディスクリプション", wait: 10)
    expect(page).to have_content("テスト用のメタディスクリプションです。")
  end
end
