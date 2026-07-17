require 'rails_helper'

RSpec.describe SiteSettingCacheManager do
  # test環境のキャッシュはnull_store（保存されない）のため、
  # キャッシュの実挙動を検証できるMemoryStoreに差し替える
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Rails).to receive(:cache).and_return(memory_store)
    SiteSetting.delete_all
  end

  it 'fetches all settings and ensures missing defaults are created' do
    SiteSetting.create!(key: 'site_title', setting_type: 'text', description: 'Title', value: 'Custom')

    settings = described_class.fetch_all_settings

    expect(settings).to be_a(Hash)
    expect(settings[:site_title].get_value).to eq('Custom')
    expect(SiteSetting.count).to eq(SiteSetting::SETTING_TYPES.size)
  end

  it 'clears caches' do
    described_class.fetch_all_settings

    described_class.clear_cache

    expect(Rails.cache.exist?(SiteSettingCacheManager::CACHE_KEY)).to eq(false)
  end

  # 監査C-9の回帰テスト:
  # 旧実装はクラス変数でメモ化していたため、別プロセスが設定を更新して
  # 共有キャッシュを消しても、自プロセスは古い値を返し続けた。
  # 「共有キャッシュの削除が次回読み込みに反映される」ことを検証する。
  it 'reflects changes after the shared cache is cleared by another process' do
    SiteSetting.create!(key: 'site_title', setting_type: 'text', description: 'Title', value: 'Before')
    expect(described_class.fetch_all_settings[:site_title].get_value).to eq('Before')

    # 別プロセスによる更新とキャッシュクリアを模倣
    SiteSetting.find_by(key: 'site_title').update_column(:value, 'After')
    Rails.cache.delete(SiteSettingCacheManager::CACHE_KEY)

    expect(described_class.fetch_all_settings[:site_title].get_value).to eq('After')
  end
end
