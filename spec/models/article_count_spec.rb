require "rails_helper"

# article_count の仕様（2026-07-15確定）:
# カテゴリ・タグの article_count は「公開中(published)の記事数」を表す。
# 下書き・予約・アーカイブはカウントしない。
RSpec.describe "article_countの整合性" do
  let(:admin_user) { create(:admin_user) }
  let(:category) { create(:category) }
  let(:tag) { create(:tag) }

  def create_article(status:, **attrs)
    published_at = status == "published" ? 1.hour.ago : nil
    create(:article, admin_user: admin_user, status: status, published_at: published_at, **attrs)
  end

  describe "カテゴリのarticle_count" do
    it "公開記事を紐づけるとカウントされる" do
      article = create_article(status: "published")
      article.categories << category

      expect(category.reload.article_count).to eq(1)
    end

    it "下書き記事を紐づけてもカウントされない" do
      article = create_article(status: "draft")
      article.categories << category

      expect(category.reload.article_count).to eq(0)
    end

    it "記事を非公開に戻すとカウントが減る" do
      article = create_article(status: "published")
      article.categories << category
      expect(category.reload.article_count).to eq(1)

      article.update!(status: "draft")

      expect(category.reload.article_count).to eq(0)
    end

    it "下書き記事を公開するとカウントが増える" do
      article = create_article(status: "draft")
      article.categories << category
      expect(category.reload.article_count).to eq(0)

      article.update!(status: "published", published_at: Time.current)

      expect(category.reload.article_count).to eq(1)
    end

    it "カテゴリを付け替えると外された側のカウントも更新される" do
      other_category = create(:category)
      article = create_article(status: "published")
      article.categories << category
      expect(category.reload.article_count).to eq(1)

      article.category_ids = [ other_category.id ]

      expect(category.reload.article_count).to eq(0)
      expect(other_category.reload.article_count).to eq(1)
    end

    it "公開記事を削除するとカウントが減る" do
      article = create_article(status: "published")
      article.categories << category
      expect(category.reload.article_count).to eq(1)

      article.destroy!

      expect(category.reload.article_count).to eq(0)
    end
  end

  describe "タグのarticle_count" do
    it "公開記事を紐づけるとカウントされる" do
      article = create_article(status: "published")
      article.tags << tag

      expect(tag.reload.article_count).to eq(1)
    end

    it "下書き記事を紐づけてもカウントされない" do
      article = create_article(status: "draft")
      article.tags << tag

      expect(tag.reload.article_count).to eq(0)
    end

    it "タグを外すと外された側のカウントが更新される" do
      other_tag = create(:tag)
      article = create_article(status: "published")
      article.tags << tag
      expect(tag.reload.article_count).to eq(1)

      article.tag_ids = [ other_tag.id ]

      expect(tag.reload.article_count).to eq(0)
      expect(other_tag.reload.article_count).to eq(1)
    end

    it "記事の非公開化でタグのカウントも減る" do
      article = create_article(status: "published")
      article.tags << tag
      expect(tag.reload.article_count).to eq(1)

      article.update!(status: "archived")

      expect(tag.reload.article_count).to eq(0)
    end

    it "popularスコープに記事ゼロのタグが出ない" do
      article = create_article(status: "published")
      article.tags << tag
      article.tag_ids = []

      expect(Tag.popular).not_to include(tag)
    end
  end

  describe "再計算タスク" do
    it "article_counts:recalculate で全カウントを実データから再計算できる" do
      article = create_article(status: "published")
      article.categories << category
      article.tags << tag
      # カウンタが壊れた状態を再現
      category.update_column(:article_count, 99)
      tag.update_column(:article_count, 99)

      Rails.application.load_tasks unless Rake::Task.task_defined?("article_counts:recalculate")
      Rake::Task["article_counts:recalculate"].execute

      expect(category.reload.article_count).to eq(1)
      expect(tag.reload.article_count).to eq(1)
    end
  end
end
