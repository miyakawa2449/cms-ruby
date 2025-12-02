class EnablePgExtensions < ActiveRecord::Migration[8.0]
  def change
    # PostgreSQL拡張機能を有効化
    enable_extension "pg_trgm"    # 全文検索用トライグラム
    enable_extension "pgcrypto"   # 暗号化機能
    enable_extension "uuid-ossp"  # UUID生成
    enable_extension "unaccent"   # アクセント除去
  end
end
