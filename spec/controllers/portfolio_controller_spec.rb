# frozen_string_literal: true

require "rails_helper"

RSpec.describe PortfolioController, type: :controller do
  describe "#index" do
    let(:works_category) { create(:category, slug: "works") }

    it "assigns visible sections with their content data" do
      visible_section = create(:section, position: 1)
      create(:section, is_visible: false)

      get :index

      expect(assigns(:sections)).to eq([visible_section])
      expect(assigns(:section_data)).to eq(visible_section.name => {})
    end

    it "assigns works articles ordered by published_at desc" do
      older = create(:article, :published, published_at: 2.days.ago)
      newer = create(:article, :published, published_at: 1.day.ago)
      [older, newer].each { |article| article.categories << works_category }
      create(:article, :published)

      get :index

      expect(assigns(:works_articles)).to eq([newer, older])
    end

    it "assigns recent published articles excluding works articles" do
      works_article = create(:article, :published)
      works_article.categories << works_category
      blog_older = create(:article, :published, published_at: 3.days.ago)
      blog_newer = create(:article, :published, published_at: 1.day.ago)
      create(:article, :draft)

      get :index

      expect(assigns(:recent_articles)).to eq([blog_newer, blog_older])
    end

    it "applies full-text search to recent articles when query is present" do
      matching = create(:article, :published, title: "Rubyのメタプログラミング入門")
      create(:article, :published, title: "AWSインフラ構築メモ")

      get :index, params: { search: "Ruby" }

      expect(assigns(:search_query)).to eq("Ruby")
      expect(assigns(:recent_articles)).to contain_exactly(matching)
    end

    # S1-7 P0-1: 例外を握りつぶして空ページ200を返す設計と、
    # ConnectionNotEstablishedの無限retryを撤去したため、例外はそのまま伝播する
    # （回帰テストは spec/requests/audit_regression_spec.rb 参照）
    it "does not swallow errors from data loading" do
      allow(Section).to receive(:visible).and_raise(StandardError, "boom")

      expect { get :index }.to raise_error(StandardError, "boom")
    end
  end
end
