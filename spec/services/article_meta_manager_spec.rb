require 'rails_helper'

RSpec.describe ArticleMetaManager do
  describe 'slug management' do
    it 'generates unique slugs' do
      create(:article, title: 'Hello World', slug: 'hello-world')
      article = build(:article, title: 'Hello World', slug: nil)
      manager = described_class.new(article)

      manager.generate_slug

      expect(article.slug).to eq('hello-world-1')
    end

    it 'updates slug based on new title' do
      article = create(:article, title: 'Old Title', slug: 'old-title')
      manager = described_class.new(article)

      manager.update_slug('New Title')

      expect(article.reload.slug).to eq('new-title')
    end
  end

  describe 'url helpers' do
    it 'uses works path when article is in works category' do
      works = Category.find_by(slug: 'works') || create(:category, slug: 'works')
      article = create(:article, slug: 'work-item')
      article.categories << works

      manager = described_class.new(article)

      expect(manager.url_path).to eq('/works/work-item')
    end

    it 'builds canonical url' do
      article = create(:article, slug: 'sample')
      manager = described_class.new(article)

      expect(manager.canonical_url('https://example.com')).to eq('https://example.com/blog/sample')
    end
  end

  describe 'SEO helpers' do
    it 'builds seo title and description' do
      article = create(:article, title: 'Meta Title')
      manager = described_class.new(article)

      expect(manager.seo_title(site_title: 'Site')).to eq('Meta Title | Site')
      expect(manager.seo_description).to eq(article.excerpt)
    end

    it 'generates keywords from tags and tech stack' do
      article = create(:article, tech_stack: 'Ruby, Rails')
      article.tags << create(:tag, name: 'Testing')
      manager = described_class.new(article)

      expect(manager.seo_keywords).to include('Testing', 'Ruby')
    end
  end

  describe 'Open Graph helpers' do
    it 'returns correct og data and twitter card type' do
      article = create(:article, og_title: nil, og_description: nil)
      manager = described_class.new(article)

      expect(manager.og_title).to eq(article.title)
      expect(manager.og_description).to be_present
      expect(manager.twitter_card_type).to eq('summary')
    end
  end

  describe 'structured data' do
    it 'builds json structure' do
      article = create(:article, slug: 'sample')
      manager = described_class.new(article)

      expect(manager.structured_data[:"@type"]).to eq('BlogPosting')
      expect(manager.structured_data_json).to include('BlogPosting')
    end
  end

  describe 'validation helpers' do
    it 'detects slug duplicates' do
      create(:article, slug: 'dup-slug')
      article = create(:article, slug: 'dup-slug-2')
      article.slug = 'dup-slug'
      manager = described_class.new(article)

      expect(manager.validate_slug_uniqueness).to eq(false)
    end

    it 'suggests unique slug from base title' do
      create(:article, title: 'Sample', slug: 'sample')
      article = build(:article, title: 'Sample')
      manager = described_class.new(article)

      expect(manager.slug_suggestion).to eq('sample-1')
    end
  end
end
