# frozen_string_literal: true

# キャッシュ監視サービス
# Redisまたはメモリキャッシュの統計情報を取得する
class CacheMonitorService
  class << self
    # キャッシュの統計情報を取得
    #
    # @return [Hash] 統計情報
    def stats
      if redis_available?
        redis_stats
      else
        memory_stats
      end
    end

    # キャッシュヒット率を計算
    #
    # @param hits [Integer] ヒット数
    # @param misses [Integer] ミス数
    # @return [Float] ヒット率（パーセンテージ）
    def calculate_hit_rate(hits, misses)
      total = hits.to_i + misses.to_i
      return 0.0 if total.zero?

      ((hits.to_f / total) * 100).round(2)
    end

    # Redisが利用可能かどうかを確認
    #
    # @return [Boolean]
    def redis_available?
      return @redis_available if defined?(@redis_available)

      @redis_available = begin
        redis_client.ping == "PONG"
      rescue StandardError
        false
      end
    end

    # キャッシュをクリア
    #
    # @return [Boolean] 成功したかどうか
    def clear_all
      Rails.cache.clear
      Rails.logger.info "[CacheMonitorService] All caches cleared"
      true
    rescue StandardError => e
      Rails.logger.error "[CacheMonitorService] Failed to clear cache: #{e.message}"
      false
    end

    private

    def redis_client
      @redis_client ||= Redis.new(url: redis_url)
    end

    def redis_url
      ENV.fetch("REDIS_URL") { "redis://localhost:6379/0" }
    end

    def redis_stats
      info = redis_client.info

      {
        store_type: :redis,
        used_memory: info["used_memory_human"],
        used_memory_peak: info["used_memory_peak_human"],
        connected_clients: info["connected_clients"].to_i,
        total_commands_processed: info["total_commands_processed"].to_i,
        keyspace_hits: info["keyspace_hits"].to_i,
        keyspace_misses: info["keyspace_misses"].to_i,
        hit_rate: calculate_hit_rate(info["keyspace_hits"], info["keyspace_misses"]),
        uptime_in_days: info["uptime_in_days"].to_i,
        redis_version: info["redis_version"]
      }
    rescue StandardError => e
      Rails.logger.error "[CacheMonitorService] Redis stats error: #{e.message}"
      error_stats(:redis, e.message)
    end

    def memory_stats
      cache = Rails.cache

      # MemoryStoreの場合は内部統計を取得
      if cache.respond_to?(:stats)
        cache_stats = cache.stats
        {
          store_type: :memory,
          entries: cache_stats[:entries] || 0,
          size: format_bytes(cache_stats[:size] || 0),
          hit_rate: 0.0, # MemoryStoreは統計を保持しない
          note: "Memory cache statistics are limited"
        }
      else
        # Solid Cacheなど他のストアの場合
        {
          store_type: cache.class.name.demodulize.underscore.to_sym,
          note: "Detailed statistics not available for this cache store",
          cache_class: cache.class.name
        }
      end
    rescue StandardError => e
      Rails.logger.error "[CacheMonitorService] Memory stats error: #{e.message}"
      error_stats(:memory, e.message)
    end

    def error_stats(store_type, message)
      {
        store_type: store_type,
        error: message,
        hit_rate: 0.0
      }
    end

    def format_bytes(bytes)
      return "0 B" if bytes.zero?

      units = %w[B KB MB GB TB]
      exp = (Math.log(bytes) / Math.log(1024)).to_i
      exp = units.length - 1 if exp > units.length - 1

      "#{(bytes.to_f / (1024**exp)).round(2)} #{units[exp]}"
    end
  end
end
