require 'rails_helper'

RSpec.describe SiteSettingCacheManager do
  before do
    Rails.cache.clear
    SiteSetting.delete_all
  end

  it 'fetches all settings and ensures missing defaults are created' do
    SiteSetting.create!(key: 'site_title', setting_type: 'text', description: 'Title', value: 'Custom')

    settings = described_class.fetch_all_settings

    expect(settings).to be_a(Hash)
    expect(settings[:site_title].get_value).to eq('Custom')
    expect(SiteSetting.count).to eq(SiteSettingTypeManager::SETTING_TYPES.size)
  end

  it 'caches individual setting values' do
    SiteSetting.create!(key: 'site_title', setting_type: 'text', description: 'Title', value: 'Custom')

    value = described_class.fetch_setting('site_title')

    expect(value).to eq('Custom')
  end

  it 'clears caches' do
    described_class.fetch_all_settings

    described_class.clear_cache

    expect(Rails.cache.exist?(SiteSettingCacheManager::CACHE_KEY)).to eq(false)
  end

  it 'returns cache stats' do
    stats = described_class.cache_stats

    expect(stats).to have_key(:all_settings)
  end
end
