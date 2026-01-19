require "rails_helper"

RSpec.describe CacheSweeper do
  let(:cache_store) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Rails).to receive(:cache).and_return(cache_store)
    cache_store.clear
  end

  def seed_article_cache
    cache_store.write("articles/page-1", "cached content")
    cache_store.write("blog/page-1", "cached blog content")
    cache_store.write("popular_articles", "cached popular")
    cache_store.write("sidebar/categories", "cached categories")
    cache_store.write("sidebar/tags", "cached tags")
  end

  def seed_sidebar_cache
    cache_store.write("sidebar/categories", "cached categories")
    cache_store.write("sidebar/tags", "cached tags")
    cache_store.write("articles/page-1", "cached content")
    cache_store.write("blog/page-1", "cached blog content")
  end

  describe Article do
    it "clears related caches on create" do
      seed_article_cache
      article = create(:article, :published)

      article.send(:clear_related_caches)

      expect(cache_store.exist?("articles/page-1")).to be(false)
      expect(cache_store.exist?("blog/page-1")).to be(false)
      expect(cache_store.exist?("popular_articles")).to be(false)
      expect(cache_store.exist?("sidebar/categories")).to be(false)
      expect(cache_store.exist?("sidebar/tags")).to be(false)
    end

    it "clears related caches on update" do
      seed_article_cache
      article = create(:article, :published)

      article.update!(title: "Updated Title")
      article.send(:clear_related_caches)

      expect(cache_store.exist?("articles/page-1")).to be(false)
      expect(cache_store.exist?("blog/page-1")).to be(false)
      expect(cache_store.exist?("popular_articles")).to be(false)
    end

    it "clears sidebar caches when categories are updated" do
      seed_sidebar_cache
      article = create(:article, :published)
      category = create(:category)

      article.update!(category_ids: [category.id])
      article.send(:clear_related_caches)

      expect(cache_store.exist?("sidebar/categories")).to be(false)
    end

    it "clears sidebar caches when tags are updated" do
      seed_sidebar_cache
      article = create(:article, :published)
      tag = create(:tag)

      article.update!(tag_ids: [tag.id])
      article.send(:clear_related_caches)

      expect(cache_store.exist?("sidebar/tags")).to be(false)
    end

    it "clears related caches on destroy" do
      seed_article_cache
      article = create(:article, :published)

      article.destroy
      article.send(:clear_related_caches)

      expect(cache_store.exist?("articles/page-1")).to be(false)
      expect(cache_store.exist?("popular_articles")).to be(false)
    end
  end

  describe Category do
    it "clears sidebar caches on update" do
      seed_sidebar_cache
      category = create(:category)

      category.update!(name: "Updated Category")
      category.send(:clear_related_caches)

      expect(cache_store.exist?("sidebar/categories")).to be(false)
    end

    it "clears article list caches on update" do
      seed_sidebar_cache
      category = create(:category)

      category.update!(name: "Updated Category")
      category.send(:clear_related_caches)

      expect(cache_store.exist?("articles/page-1")).to be(false)
      expect(cache_store.exist?("blog/page-1")).to be(false)
    end
  end

  describe Tag do
    it "clears sidebar caches on update" do
      seed_sidebar_cache
      tag = create(:tag)

      tag.update!(name: "Updated Tag")
      tag.send(:clear_related_caches)

      expect(cache_store.exist?("sidebar/tags")).to be(false)
    end

    it "clears article list caches on update" do
      seed_sidebar_cache
      tag = create(:tag)

      tag.update!(name: "Updated Tag")
      tag.send(:clear_related_caches)

      expect(cache_store.exist?("articles/page-1")).to be(false)
      expect(cache_store.exist?("blog/page-1")).to be(false)
    end
  end
end
