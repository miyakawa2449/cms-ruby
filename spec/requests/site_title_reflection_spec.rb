require "rails_helper"

# 監査H-7の回帰テスト:
# 管理画面の site_title / site_description が公開ページの
# <title>・OGP・meta description に反映されること。
# また、設計世代の混在による「タイトル/説明文の二重出力」が無いこと。
RSpec.describe "サイトタイトル設定の反映", type: :request do
  let(:admin_user) { create(:admin_user) }

  before do
    SiteSetting.delete_all
    SiteSetting.create!(key: "site_title", setting_type: "text", description: "t", value: "テストサイト")
    SiteSetting.create!(key: "site_description", setting_type: "text", description: "d", value: "テスト用の説明文")
  end

  describe "トップページ" do
    it "titleとog:site_nameとdescriptionに設定値が反映される" do
      get root_path

      expect(response.body).to include("<title>テストサイト</title>")
      expect(response.body).to include('property="og:site_name" content="テストサイト"')
      expect(response.body).to include('name="description" content="テスト用の説明文"')
    end

    it "titleタグとmeta descriptionは1つずつしか出力されない（二重出力の防止）" do
      get root_path

      expect(response.body.scan("<title").count).to eq(1)
      expect(response.body.scan('name="description"').count).to eq(1)
    end
  end

  describe "ブログ一覧" do
    it "titleに設定値が反映される" do
      get blog_path

      expect(response.body).to include("<title>Blog | テストサイト</title>")
      expect(response.body).to include('property="og:site_name" content="テストサイト"')
    end
  end

  describe "記事ページ" do
    it "titleが「記事名 | サイト名」になり、二重にならない" do
      article = create(:article, admin_user: admin_user, title: "テスト記事",
                       status: "published", published_at: 1.hour.ago)

      get blog_article_path(article.slug)

      expect(response.body).to include("<title>テスト記事 | テストサイト</title>")
      expect(response.body.scan("<title").count).to eq(1)
    end
  end

  describe "開発者固有のフォールバック排除" do
    it "設定が反映されたページに旧ハードコード文字列が残らない" do
      get root_path

      expect(response.body).not_to include("宮川 剛 - シニアエンジニアのポートフォリオ")
    end
  end
end
