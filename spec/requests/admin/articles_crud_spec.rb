require "rails_helper"

RSpec.describe "Admin::Articles CRUD", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:valid_params) { { article: attributes_for(:article) } }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe "記事詳細のプレビュー表示" do
    it "本文がMarkdownとしてHTML描画される（生テキスト表示にならない）" do
      article = create(:article, admin_user: admin_user, content: "**強調テキスト**\n\n## 見出し2")

      get admin_article_path(article)

      expect(response.body).to include("<strong>強調テキスト</strong>")
      expect(response.body).to include("見出し2</h2>")
    end
  end

  describe "予約投稿" do
    it "予約時刻付きで予約投稿を作成できる" do
      scheduled_time = 1.day.from_now.change(sec: 0)
      params = { article: attributes_for(:article).merge(status: "scheduled", published_at: scheduled_time) }

      post admin_articles_path, params: params

      article = Article.order(:created_at).last
      expect(article.status).to eq("scheduled")
      expect(article.published_at).to be_within(1.second).of(scheduled_time)
    end

    it "予約時刻なしの予約投稿は保存できない" do
      params = { article: attributes_for(:article).merge(status: "scheduled", published_at: nil) }

      expect {
        post admin_articles_path, params: params
      }.not_to change(Article, :count)
    end
  end

  describe "記事作成フロー" do
    it "記事作成ページが表示される" do
      get new_admin_article_path

      expect(response).to have_http_status(:success)
    end

    it "記事を作成できる" do
      expect {
        post admin_articles_path, params: valid_params
      }.to change(Article, :count).by(1)
    end

    it "作成後に記事詳細へリダイレクトされる" do
      post admin_articles_path, params: valid_params

      expect(response).to redirect_to(admin_article_path(Article.last))
    end

    it "バリデーションエラーでunprocessable_entityを返す" do
      post admin_articles_path, params: { article: { title: "", content: "" } }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "タグとカテゴリを設定できる" do
      category = create(:category)

      post admin_articles_path, params: {
        article: attributes_for(:article).merge(
          tag_names: "Ruby, Rails",
          category_ids: [ category.id ]
        )
      }

      article = Article.last
      expect(article.tags.pluck(:name)).to include("Ruby", "Rails")
      expect(article.categories).to include(category)
    end
  end

  describe "編集フロー" do
    let!(:article) { create(:article, admin_user: admin_user) }

    it "記事編集ページが表示される" do
      get edit_admin_article_path(article)

      expect(response).to have_http_status(:success)
    end

    it "記事タイトルを更新できる" do
      patch admin_article_path(article), params: {
        article: { title: "更新後タイトル" }
      }

      expect(article.reload.title).to eq("更新後タイトル")
    end

    it "不正な更新はunprocessable_entityを返す" do
      patch admin_article_path(article), params: {
        article: { title: "" }
      }

      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "カテゴリを更新できる" do
      category = create(:category)

      patch admin_article_path(article), params: {
        article: { category_ids: [ category.id ] }
      }

      expect(article.reload.categories).to include(category)
    end

    it "タグを更新できる" do
      patch admin_article_path(article), params: {
        article: { tag_names: "RSpec, Testing" }
      }

      expect(article.reload.tags.pluck(:name)).to include("RSpec", "Testing")
    end
  end

  describe "削除フロー" do
    let!(:article) { create(:article, admin_user: admin_user) }

    it "記事を削除できる" do
      article

      expect {
        delete admin_article_path(article)
      }.to change(Article, :count).by(-1)
    end

    it "削除後に一覧へリダイレクトされる" do
      delete admin_article_path(article)

      expect(response).to redirect_to(admin_articles_path)
    end

    it "関連するAiGenerationが削除される" do
      create(:ai_generation, article: article, admin_user: admin_user)

      expect {
        delete admin_article_path(article)
      }.to change(AiGeneration, :count).by(-1)
    end

    it "ArticleTagが削除される" do
      tag = create(:tag)
      article.tags << tag

      expect {
        delete admin_article_path(article)
      }.to change(ArticleTag, :count).by(-1)
    end

    it "ArticleCategoryが削除される" do
      category = create(:category)
      article.categories << category

      expect {
        delete admin_article_path(article)
      }.to change { ArticleCategory.where(article_id: article.id).count }.by(-1)
    end
  end

  describe "公開フロー" do
    let!(:article) { create(:article, :draft, admin_user: admin_user) }

    it "公開するとpublishedになる" do
      patch publish_admin_article_path(article)

      expect(article.reload.status).to eq("published")
    end

    it "公開後に一覧へリダイレクトされる" do
      patch publish_admin_article_path(article)

      expect(response).to redirect_to(admin_articles_path)
    end

    it "非公開にするとdraftになる" do
      article.update!(status: "published", published_at: Time.current)

      patch unpublish_admin_article_path(article)

      expect(article.reload.status).to eq("draft")
    end

    it "非公開後に一覧へリダイレクトされる" do
      article.update!(status: "published", published_at: Time.current)

      patch unpublish_admin_article_path(article)

      expect(response).to redirect_to(admin_articles_path)
    end

    it "公開時にpublished_atが設定される" do
      patch publish_admin_article_path(article)

      expect(article.reload.published_at).to be_present
    end
  end
end
