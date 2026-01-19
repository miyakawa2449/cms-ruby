# frozen_string_literal: true

# キャッシュ無効化のための共通モジュール
# モデルの変更時に関連するキャッシュを自動的にクリアする
#
# @example モデルでの使用
#   class Article < ApplicationRecord
#     include CacheSweeper
#
#     private
#
#     def clear_related_caches
#       Rails.cache.delete_matched("articles/page-*")
#     end
#   end
#
module CacheSweeper
  extend ActiveSupport::Concern

  included do
    after_commit :clear_related_caches, on: [ :create, :update, :destroy ]
  end

  private

  # サブクラスでオーバーライドして、クリアするキャッシュを指定
  def clear_related_caches
    # デフォルトでは何もしない
    # サブクラスで実装する
    Rails.logger.debug "[CacheSweeper] No cache clearing defined for #{self.class.name}"
  end

  # キャッシュキーを削除するヘルパーメソッド
  def clear_cache(key)
    Rails.cache.delete(key)
    Rails.logger.info "[CacheSweeper] Cleared cache: #{key}"
  end

  # パターンマッチでキャッシュを削除するヘルパーメソッド
  # 注意: delete_matchedは一部のキャッシュストア（MemoryStore, RedisStore等）でのみサポート
  def clear_cache_matched(pattern)
    if Rails.cache.respond_to?(:delete_matched)
      Rails.cache.delete_matched(pattern)
      Rails.logger.info "[CacheSweeper] Cleared cache pattern: #{pattern}"
    else
      Rails.logger.warn "[CacheSweeper] Cache store does not support delete_matched: #{pattern}"
    end
  end
end
