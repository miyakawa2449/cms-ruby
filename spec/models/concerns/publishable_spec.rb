require 'rails_helper'

RSpec.describe Publishable do
  include ActiveSupport::Testing::TimeHelpers

  before do
    ActiveRecord::Base.connection.reset_pk_sequence!("sections")
  end

  class PublishableStorySection < MyStorySection
    include Publishable
  end

  class PublishableActiveContent
    def self.scope(*); end
    include Publishable
    attr_accessor :active_content
  end

  class PublishableNameOnly
    def self.scope(*); end
    include Publishable
    attr_accessor :name
  end

  class PublishableTitleContent
    def self.scope(*); end
    include Publishable
    attr_accessor :title, :content
  end

  class PublishablePlain
    def self.scope(*); end
    include Publishable
  end

  it 'evaluates article publish states' do
    travel_to Time.zone.local(2026, 1, 10, 10, 0, 0) do
      article = create(:article, status: 'published', published_at: 1.day.ago)

      expect(article.published?).to eq(true)
      expect(article.draft?).to eq(false)
      expect(article.status_display).to eq('公開中')
    end
  end

  it 'handles scheduled display text' do
    travel_to Time.zone.local(2026, 1, 10, 10, 0, 0) do
      article = create(:article, status: 'published', published_at: 2.days.from_now)

      expect(article.published?).to eq(false)
      expect(article.status_display).to eq('公開予定')
    end
  end

  it 'toggles published state and sets published_at' do
    travel_to Time.zone.local(2026, 1, 10, 10, 0, 0) do
      article = create(:article, status: 'draft', published_at: nil)

      article.toggle_published!

      expect(article.status).to eq('published')
      expect(article.published_at).to be_present

      article.set_published_at!
      expect(article.published_at).to be_present
    end
  end

  it 'toggles back to draft when already published' do
    article = create(:article, status: 'published', published_at: 1.day.ago)

    article.toggle_published!

    expect(article.status).to eq('draft')
    expect(article.published_at).to be_nil
  end

  it 'uses visibility flags when status is absent' do
    section = create(:section, name: 'hero-hidden', display_name: 'Hero', is_visible: false)

    expect(section.published?).to eq(false)
    expect(section.draft?).to eq(true)
    expect(section.status_display).to eq('非表示')
  end

  it 'treats visible sections as published' do
    section = create(:section, name: 'hero-visible', display_name: 'Hero', is_visible: true)

    expect(section.published?).to eq(true)
    expect(section.draft?).to eq(false)
  end

  it 'returns status labels for scheduled and archived states' do
    article = create(:article, status: 'scheduled', published_at: 1.day.from_now)
    archived = create(:article, status: 'archived')

    expect(article.scheduled?).to eq(true)
    expect(article.status_display).to include('予約投稿')
    expect(archived.archived?).to eq(true)
    expect(archived.status_display).to eq('アーカイブ')
  end

  it 'falls back to humanized status for unknown status' do
    article = create(:article)
    article.update_column(:status, 'custom')

    expect(article.status_display).to eq('Custom')
  end

  it 'toggles visibility for visible models' do
    section = create(:section, name: 'toggle', display_name: 'Toggle', is_visible: true)

    section.toggle_published!

    expect(section.is_visible).to eq(false)
  end

  it 'uses is_active branch when present' do
    section = PublishableStorySection.create!(
      section_type: 'chapter_1',
      title: 'Chapter',
      is_active: false,
      additional_data: {}
    )

    expect(section.published?).to eq(false)
    expect(section.status_display).to eq('無効')
    section.toggle_published!
    expect(section.is_active).to eq(true)
  end

  it 'uses active content when no status flags are present' do
    model = PublishableActiveContent.new

    model.active_content = "data"
    expect(model.published?).to eq(true)

    model.active_content = nil
    expect(model.published?).to eq(false)
    expect(model.status_display).to eq("不明")
  end

  it 'evaluates publishable? with title/content and name branches' do
    title_content = PublishableTitleContent.new
    title_content.title = "Title"
    title_content.content = nil

    expect(title_content.publishable?).to eq(false)

    title_content.content = "Body"
    expect(title_content.publishable?).to eq(true)

    named = PublishableNameOnly.new
    named.name = ""
    expect(named.publishable?).to eq(false)
    named.name = "Section"
    expect(named.publishable?).to eq(true)
  end

  it 'defaults to publishable for plain objects' do
    plain = PublishablePlain.new

    expect(plain.publishable?).to eq(true)
    expect(plain.published?).to eq(true)
    expect(plain.draft?).to eq(false)
    expect(plain.status_display).to eq("不明")
  end
end
