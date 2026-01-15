require 'rails_helper'

RSpec.describe "Blog", type: :request do
  describe "GET /blog" do
    context "通常表示（検索なし）" do
      it "公開記事一覧を表示する" do
        published_article = create(:article, :published, title: "公開記事")
        draft_article = create(:article, :draft, title: "下書き記事")

        get blog_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include(published_article.title)
        expect(response.body).not_to include(draft_article.title)
      end

      it "ページネーションが機能する" do
        now = Time.zone.now
        articles = (1..15).map do |index|
          create(:article, :published, title: "記事#{index}", published_at: now - index.minutes)
        end

        get blog_path, params: { page: 1 }

        sorted_titles = articles.sort_by(&:published_at).reverse.map(&:title)
        sorted_titles.first(10).each do |title|
          expect(response.body).to include(title)
        end
        sorted_titles.drop(10).each do |title|
          expect(response.body).not_to include(title)
        end
      end
    end

    context "キーワード検索" do
      it "検索結果を表示する" do
        article = create(:article, :published, title: "Ruby on Rails入門")

        get blog_path, params: { q: "Rails" }

        expect(response).to have_http_status(:success)
        expect(response.body).to include(blog_article_path(article.slug))
        expect(response.body).to include("Rails")
      end

      it "キーワードにマッチしない記事は表示されない" do
        matching_article = create(:article, :published, title: "Ruby on Rails入門")
        non_matching_article = create(:article, :published, title: "Python入門")

        get blog_path, params: { q: "Rails" }

        expect(response.body).to include(blog_article_path(matching_article.slug))
        expect(response.body).not_to include(blog_article_path(non_matching_article.slug))
      end

      it "検索結果件数が取得できる" do
        create_list(:article, 5, :published, title: "Rails入門")
        create(:article, :published, title: "Python入門")

        get blog_path, params: { q: "Rails" }

        expect(response.body).to include("検索結果")
        expect(response.body).to include(">5</span>件")
      end
    end

    context "カテゴリフィルタ" do
      it "カテゴリで絞り込みができる" do
        category = create(:category, name: "プログラミング")
        article1 = create(:article, :published, title: "カテゴリ記事")
        article1.categories << category
        article2 = create(:article, :published, title: "別記事")

        get blog_path, params: { category_id: category.id }

        expect(response.body).to include(article1.title)
        expect(response.body).not_to include(article2.title)
        expect(response.body).to include(category.name)
      end
    end

    context "タグフィルタ" do
      it "タグで絞り込みができる" do
        tag = create(:tag, name: "Ruby")
        article1 = create(:article, :published, title: "タグ記事")
        article1.tags << tag
        article2 = create(:article, :published, title: "別記事")

        get blog_path, params: { tag_id: tag.id }

        expect(response.body).to include(article1.title)
        expect(response.body).not_to include(article2.title)
        expect(response.body).to include(tag.name)
      end
    end

    context "複合条件検索" do
      it "複数条件で絞り込みができる" do
        category = create(:category, name: "プログラミング")
        tag = create(:tag, name: "Rails")
        article1 = create(:article, :published, title: "Rails入門")
        article1.categories << category
        article1.tags << tag
        article2 = create(:article, :published, title: "Rails応用")
        article2.tags << tag

        get blog_path, params: { q: "Rails", category_id: category.id, tag_id: tag.id }

        expect(response.body).to include(blog_article_path(article1.slug))
        expect(response.body).not_to include(blog_article_path(article2.slug))
      end
    end

    context "SEO" do
      it "検索時はnoindexが設定される" do
        get blog_path, params: { q: "Rails" }

        expect(response).to have_http_status(:success)
      end

      it "カテゴリフィルタ時もnoindexが設定される" do
        category = create(:category)

        get blog_path, params: { category_id: category.id }

        expect(response).to have_http_status(:success)
      end

      it "タグフィルタ時もnoindexが設定される" do
        tag = create(:tag)

        get blog_path, params: { tag_id: tag.id }

        expect(response).to have_http_status(:success)
      end
    end
  end
end
