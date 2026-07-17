# frozen_string_literal: true

require "rails_helper"

# S1-7 P5-2: 管理画面の記事一覧フィルタ（5軸: status/category/tag/search/work_type）
# P1-1のリファクタリング（スコープへの統合）前後で挙動が変わらないことを保証する特性テスト
RSpec.describe ArticleFilterService do
  let(:service) { described_class.new }

  describe "#filter" do
    context "statusフィルタ" do
      let!(:published) { create(:article, :published) }
      let!(:draft) { create(:article, :draft) }
      let!(:scheduled) { create(:article, status: "scheduled", published_at: 1.day.from_now) }

      it "publishedで公開済みのみ返す" do
        expect(service.filter(status: "published")).to contain_exactly(published)
      end

      it "draftで下書きのみ返す" do
        expect(service.filter(status: "draft")).to contain_exactly(draft)
      end

      it "scheduledで予約投稿のみ返す" do
        expect(service.filter(status: "scheduled")).to contain_exactly(scheduled)
      end

      it "未指定なら全件返す" do
        expect(service.filter({})).to contain_exactly(published, draft, scheduled)
      end

      it "空文字なら全件返す（境界値）" do
        expect(service.filter(status: "")).to contain_exactly(published, draft, scheduled)
      end
    end

    context "categoryフィルタ" do
      let!(:category) { create(:category) }
      let!(:in_category) { create(:article, categories: [category]) }
      let!(:out_of_category) { create(:article) }

      it "指定カテゴリの記事のみ返す" do
        expect(service.filter(category_id: category.id)).to contain_exactly(in_category)
      end

      it "存在しないカテゴリIDなら0件（境界値）" do
        expect(service.filter(category_id: -1)).to be_empty
      end
    end

    context "tagフィルタ" do
      let!(:tag) { create(:tag) }
      let!(:tagged) { create(:article, tags: [tag]) }
      let!(:untagged) { create(:article) }

      it "指定タグの記事のみ返す" do
        expect(service.filter(tag_id: tag.id)).to contain_exactly(tagged)
      end

      it "存在しないタグIDなら0件（境界値）" do
        expect(service.filter(tag_id: -1)).to be_empty
      end
    end

    context "searchフィルタ（管理画面はILIKEによる正確な部分一致を維持）" do
      let!(:title_hit) { create(:article, title: "Rails入門ガイド") }
      let!(:content_hit) { create(:article, content: "本文にRailsの話") }
      let!(:excerpt_hit) { create(:article, excerpt: "抜粋にRails") }
      let!(:no_hit) { create(:article, title: "Python基礎", content: "内容", excerpt: "概要") }

      it "タイトル・本文・抜粋を部分一致で横断検索する" do
        expect(service.filter(search: "Rails"))
          .to contain_exactly(title_hit, content_hit, excerpt_hit)
      end

      it "大文字小文字を区別しない" do
        expect(service.filter(search: "rails"))
          .to contain_exactly(title_hit, content_hit, excerpt_hit)
      end

      it "一致なしなら0件" do
        expect(service.filter(search: "存在しない語句")).to be_empty
      end

      it "空文字なら全件返す（境界値）" do
        expect(service.filter(search: "").count).to eq(4)
      end
    end

    context "work_typeフィルタ" do
      let!(:github_article) { create(:article, work_type: "github") }
      let!(:external_article) { create(:article, work_type: "external_url") }

      it "指定work_typeの記事のみ返す" do
        expect(service.filter(work_type: "github")).to contain_exactly(github_article)
      end
    end

    context "複数軸の組み合わせ" do
      let!(:category) { create(:category) }
      let!(:target) do
        create(:article, :published, title: "Rails実践", categories: [category])
      end

      before do
        create(:article, :published, title: "Rails実践")            # カテゴリ外
        create(:article, :draft, title: "Rails実践", categories: [category]) # 下書き
        create(:article, :published, title: "Python", categories: [category]) # 検索不一致
      end

      it "全条件をANDで絞り込む" do
        result = service.filter(status: "published", category_id: category.id, search: "Rails")
        expect(result).to contain_exactly(target)
      end
    end

    context "ページネーション" do
      before { create_list(:article, 3) }

      it "Kaminariでページングされたリレーションを返す" do
        result = service.filter(page: 1)
        expect(result).to respond_to(:current_page)
        expect(result.current_page).to eq(1)
      end
    end

    context "初期リレーションの注入" do
      let!(:draft) { create(:article, :draft) }

      before { create(:article, :published) }

      it "コンストラクタで渡したスコープを起点にフィルタする" do
        result = described_class.new(Article.draft).filter({})
        expect(result).to contain_exactly(draft)
      end
    end
  end
end
