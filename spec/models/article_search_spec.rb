require 'rails_helper'

RSpec.describe Article, 'pg_search full-text search', type: :model do
  let!(:admin_user) { AdminUser.first || AdminUser.create!(email: 'test@example.com', password: 'password123') }

  let!(:ruby_article) do
    Article.create!(
      title: 'Ruby on Railsの基礎',
      content: 'Rubyは美しいプログラミング言語です。Railsフレームワークを使って開発します。',
      excerpt: 'Ruby on Railsの入門記事',
      slug: 'ruby-on-rails-basics',
      status: 'published',
      published_at: 1.day.ago,
      admin_user: admin_user
    )
  end

  let!(:javascript_article) do
    Article.create!(
      title: 'JavaScriptモダン開発',
      content: 'JavaScriptでモダンなWebアプリケーションを構築する方法を解説します。',
      excerpt: 'JavaScript開発のベストプラクティス',
      slug: 'javascript-modern-dev',
      status: 'published',
      published_at: 2.days.ago,
      admin_user: admin_user
    )
  end

  let!(:draft_article) do
    Article.create!(
      title: 'Ruby下書き記事',
      content: 'この記事は下書きです。',
      excerpt: '下書き',
      slug: 'ruby-draft',
      status: 'draft',
      admin_user: admin_user
    )
  end

  describe '.full_text_search' do
    it 'finds articles by title' do
      results = Article.full_text_search('Ruby')
      expect(results).to include(ruby_article)
    end

    it 'finds articles by content' do
      results = Article.full_text_search('プログラミング')
      expect(results).to include(ruby_article)
    end

    it 'finds articles by excerpt' do
      results = Article.full_text_search('ベストプラクティス')
      expect(results).to include(javascript_article)
    end

    it 'returns results ranked by relevance' do
      results = Article.full_text_search('Ruby')
      expect(results.first).to eq(ruby_article)
    end
  end

  describe '.search scope' do
    it 'returns all articles when query is blank' do
      expect(Article.search('')).to eq(Article.all)
      expect(Article.search(nil)).to eq(Article.all)
    end

    it 'finds articles matching the query' do
      results = Article.search('Rails')
      expect(results).to include(ruby_article)
      expect(results).not_to include(javascript_article)
    end

    it 'works with published scope' do
      results = Article.published.search('Ruby')
      expect(results).to include(ruby_article)
      expect(results).not_to include(draft_article)
    end
  end

  describe '.search_ilike fallback' do
    it 'performs ILIKE search' do
      results = Article.search_ilike('Ruby')
      expect(results).to include(ruby_article)
    end

    it 'is case insensitive' do
      results = Article.search_ilike('ruby')
      expect(results).to include(ruby_article)
    end
  end

  describe 'Japanese text search' do
    it 'finds articles with Japanese query' do
      results = Article.search('開発')
      expect(results).to include(javascript_article)
    end

    it 'finds partial Japanese matches' do
      results = Article.search('プログラミング')
      expect(results).to include(ruby_article)
    end
  end
end
