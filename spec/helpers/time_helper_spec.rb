require 'rails_helper'

RSpec.describe TimeHelper, type: :helper do
  include ActiveSupport::Testing::TimeHelpers

  it 'formats time ago in Japanese' do
    travel_to Time.zone.local(2026, 1, 10, 12, 0, 0) do
      expect(helper.time_ago_in_words_ja(10.seconds.ago)).to eq('10秒前')
      expect(helper.time_ago_in_words_ja(2.hours.ago)).to eq('2時間前')
    end
  end

  it 'formats article published at text' do
    travel_to Time.zone.local(2026, 1, 10, 12, 0, 0) do
      article = create(:article, status: 'published', published_at: 2.days.ago)
      expect(helper.article_published_at(article)).to include('日前')

      article.update!(published_at: 2.weeks.ago)
      expect(helper.article_published_at(article)).to match(/\d{4}年\d{2}月\d{2}日/)
    end
  end

  it 'formats dates and datetimes' do
    date = Date.new(2026, 1, 10)
    time = Time.zone.local(2026, 1, 10, 9, 30, 0)

    expect(helper.format_date_ja(date)).to eq('2026年01月10日')
    expect(helper.format_datetime_ja(time)).to eq('2026年01月10日 09:30')
    expect(helper.admin_datetime(time)).to eq('2026-01-10 09:30:00')
    expect(helper.iso8601_datetime(time)).to include('2026-01-10')
  end
end
