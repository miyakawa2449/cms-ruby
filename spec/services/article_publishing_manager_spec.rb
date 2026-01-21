require 'rails_helper'

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

    it 'archives articles' do
      article = build_article(status: 'draft')
      manager = described_class.new(article)

      manager.archive!

      expect(article.reload.status).to eq('archived')
    end

    it 'schedules and reschedules future publications' do
      article = build_article(status: 'draft')
      manager = described_class.new(article)

      future_time = 2.days.from_now
      manager.schedule!(published_at: future_time)

      expect(article.reload.status).to eq('scheduled')

      new_time = 3.days.from_now
      manager.reschedule!(new_published_at: new_time)

      expect(article.reload.published_at.to_i).to eq(new_time.to_i)
    end

    it 'rejects scheduling in the past' do
      article = build_article(status: 'draft')
      manager = described_class.new(article)

      expect {
        manager.schedule!(published_at: 1.day.ago)
      }.to raise_error(ArgumentError)
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
        expect(manager.published_recently?).to eq(true)
      end
    end

    it 'detects overdue scheduled articles' do
      travel_to Time.zone.local(2026, 1, 10, 10, 0, 0) do
        article = build_article(status: 'scheduled', published_at: 1.day.ago)
        manager = described_class.new(article)

        expect(manager.overdue?).to eq(false)
      end
    end
  end

  describe 'validation helpers' do
    it 'checks publishing requirements' do
      article = build_article(status: 'draft')
      manager = described_class.new(article)

      expect(manager.valid_for_publishing?).to eq(true)

      article.title = nil
      expect(manager.valid_for_publishing?).to eq(false)
    end

    it 'validates scheduled articles for future date' do
      travel_to Time.zone.local(2026, 1, 10, 10, 0, 0) do
        article = build_article(status: 'scheduled', published_at: 1.day.ago)
        manager = described_class.new(article)

        errors = manager.validate_publishing_requirements
        expect(errors).to include('Published date must be in the future for scheduled articles')
      end
    end
  end

  describe '#status_display' do
    it 'returns display text for statuses' do
      article = build_article(status: 'draft')
      manager = described_class.new(article)

      expect(manager.status_display).to eq('下書き')

      article.update!(status: 'archived')
      expect(manager.status_display).to eq('アーカイブ')
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
