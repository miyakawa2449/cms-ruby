require "rails_helper"

RSpec.describe "Cache hit rate", type: :request do
  it "sidebar cache hit rate is at least 80%" do
    skip "Fragment cache is not implemented for sidebar yet"

    stats = CacheMonitorService.stats
    expect(stats[:hit_rate]).to be >= 80.0
  end

  it "article list cache is used" do
    skip "Fragment cache is not implemented for article list yet"

    get blog_path
    stats = CacheMonitorService.stats
    expect(stats[:hit_rate]).to be > 0
  end
end
