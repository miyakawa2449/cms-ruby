require "rails_helper"

RSpec.describe CacheMonitorService do
  before do
    described_class.instance_variable_set(:@redis_client, nil)
    described_class.instance_variable_set(:@redis_available, nil)
  end

  describe ".calculate_hit_rate" do
    it "returns 0.0 when total is zero" do
      expect(described_class.calculate_hit_rate(0, 0)).to eq(0.0)
    end

    it "calculates hit rate correctly" do
      expect(described_class.calculate_hit_rate(8, 2)).to eq(80.0)
    end
  end

  describe ".stats" do
    context "when Redis is available" do
      let(:redis) do
        instance_double(
          Redis,
          ping: "PONG",
          info: {
            "used_memory_human" => "1.0M",
            "used_memory_peak_human" => "2.0M",
            "connected_clients" => "2",
            "total_commands_processed" => "120",
            "keyspace_hits" => "8",
            "keyspace_misses" => "2",
            "uptime_in_days" => "1",
            "redis_version" => "7.0"
          }
        )
      end

      before do
        allow(Redis).to receive(:new).and_return(redis)
        allow(described_class).to receive(:redis_available?).and_return(true)
      end

      it "returns Redis statistics" do
        stats = described_class.stats

        expect(stats[:store_type]).to eq(:redis)
        expect(stats[:used_memory]).to eq("1.0M")
        expect(stats[:connected_clients]).to eq(2)
        expect(stats[:total_commands_processed]).to eq(120)
        expect(stats[:hit_rate]).to eq(80.0)
      end
    end

    context "when Redis stats retrieval fails" do
      let(:redis) { instance_double(Redis, ping: "PONG") }

      before do
        allow(Redis).to receive(:new).and_return(redis)
        allow(described_class).to receive(:redis_available?).and_return(true)
        allow(redis).to receive(:info).and_raise(StandardError, "boom")
      end

      it "returns error stats" do
        stats = described_class.stats

        expect(stats[:store_type]).to eq(:redis)
        expect(stats[:error]).to eq("boom")
        expect(stats[:hit_rate]).to eq(0.0)
      end
    end

    context "when Redis is unavailable" do
      before do
        allow(described_class).to receive(:redis_available?).and_return(false)
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
      end

      it "returns memory store stats" do
        stats = described_class.stats

        expect(stats[:store_type]).to eq(:memory_store)
        expect(stats[:note]).to include("Detailed statistics not available")
      end
    end
  end
end
