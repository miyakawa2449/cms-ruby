require 'rails_helper'

# S1-7 P1-6: 記事公開ロジックの唯一の実装（ArticlePublishingService・Publishableの
# 記事系メソッドは削除済み）。can_*/analytics系の未使用メソッドも削除済み
RSpec.describe ArticlePublishingManager do
  include ActiveSupport::Testing::TimeHelpers

  let(:category) { create(:category) }
  let(:tag) { create(:tag) }

  def build_article(status: 'draft', published_at: nil)
    article = create(:article, status: status, published_at: published_at)
    article.categories << category
    article.tags << tag
    article
  end

  describe 'status transitions' do
    it 'publishes and unpublishes articles' do
      article = build_article(status: 'draft')
      manager = described_class.new(article)

      manager.publish!

      expect(article.reload.status).to eq('published')
      expect(article.published_at).to be_present

      manager.unpublish!

      expect(article.reload.status).to eq('draft')
    end

    it 'unpublish!は公開日時を温存する（2026-07-17仕様確定: 再公開しても元の日付を維持）' do
      original_time = Time.zone.local(2026, 1, 5, 9, 0, 0)
      article = build_article(status: 'draft')
      manager = described_class.new(article)
      manager.publish!(published_at: original_time)

      manager.unpublish!

      expect(article.reload.published_at).to eq(original_time)
    end
  end

  describe 'コントローラ向け結果ハッシュ版（旧ArticlePublishingServiceの置き換え）' do
    describe '#publish' do
      it '成功時にsuccess:trueとメッセージを返す' do
        article = build_article(status: 'draft')

        result = described_class.new(article).publish

        expect(result[:success]).to be true
        expect(result[:message]).to eq('記事を公開しました。')
        expect(article.reload.status).to eq('published')
      end

      it '保存失敗時にsuccess:falseとエラー内容を返す' do
        article = build_article(status: 'draft')
        article.title = ''

        result = described_class.new(article).publish

        expect(result[:success]).to be false
        expect(result[:message]).to eq('公開に失敗しました。')
        expect(result[:errors]).to be_present
        expect(article.reload.status).to eq('draft')
      end
    end

    describe '#unpublish' do
      it '成功時にsuccess:trueとメッセージを返す' do
        article = build_article(status: 'published', published_at: 1.day.ago)

        result = described_class.new(article).unpublish

        expect(result[:success]).to be true
        expect(result[:message]).to eq('記事を非公開にしました。')
        expect(article.reload.status).to eq('draft')
      end
    end
  end

  describe 'status checks' do
    it 'evaluates published and scheduled states' do
      travel_to Time.zone.local(2026, 1, 10, 10, 0, 0) do
        article = build_article(status: 'published', published_at: 1.day.ago)
        manager = described_class.new(article)

        expect(manager.published?).to eq(true)
        expect(manager.draft?).to eq(false)
        expect(manager.scheduled?).to eq(false)
      end
    end
  end

  describe '.publish_scheduled_articles!' do
    it 'publishes scheduled articles whose time has passed' do
      travel_to Time.zone.local(2026, 1, 10, 10, 0, 0) do
        article = build_article(status: 'scheduled', published_at: 1.day.ago)

        described_class.publish_scheduled_articles!

        expect(article.reload.status).to eq('published')
      end
    end
  end
end
