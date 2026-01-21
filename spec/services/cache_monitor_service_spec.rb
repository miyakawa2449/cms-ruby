require 'rails_helper'

RSpec.describe CacheMonitorService do
  it 'calculates hit rate safely' do
    expect(described_class.calculate_hit_rate(5, 5)).to eq(50.0)
    expect(described_class.calculate_hit_rate(0, 0)).to eq(0.0)
  end

  it 'returns redis stats when available' do
    redis = instance_double(Redis, ping: 'PONG', info: {
      'used_memory_human' => '1MB',
      'used_memory_peak_human' => '2MB',
      'connected_clients' => '1',
      'total_commands_processed' => '10',
      'keyspace_hits' => '5',
      'keyspace_misses' => '5',
      'uptime_in_days' => '1',
      'redis_version' => '7.0'
    })

    allow(described_class).to receive(:redis_available?).and_return(true)
    allow(described_class).to receive(:redis_client).and_return(redis)

    stats = described_class.stats

    expect(stats[:store_type]).to eq(:redis)
    expect(stats[:hit_rate]).to eq(50.0)
  end

  it 'returns memory stats when redis is unavailable' do
    cache = double('CacheStore', stats: { entries: 1, size: 1024 })
    allow(described_class).to receive(:redis_available?).and_return(false)
    allow(Rails).to receive(:cache).and_return(cache)

    stats = described_class.stats

    expect(stats[:store_type]).to eq(:memory)
  end

  it 'clears cache and handles errors' do
    allow(Rails.cache).to receive(:clear).and_return(true)
    expect(described_class.clear_all).to eq(true)

    allow(Rails.cache).to receive(:clear).and_raise(StandardError, 'boom')
    expect(described_class.clear_all).to eq(false)
  end
end
