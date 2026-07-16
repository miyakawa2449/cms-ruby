# 管理画面パスの決定元を起動時にログへ記録する（監査C-10の付随対応）。
# 優先順位は DB履歴 > 環境変数ADMIN_PATH > デフォルト値。
# 「ENVを変えたのに反映されない（DB履歴が優先されていた）」という
# 運用時の混乱を防ぐため、決定元と食い違いの有無だけを出力する（パス値自体は秘匿）。
Rails.application.config.after_initialize do
  begin
    db_path = AdminPathHistory.order(created_at: :desc).limit(1).pick(:new_path)
    env_path = ENV["ADMIN_PATH"]

    source =
      if db_path.present?
        "DB履歴（管理画面からの変更/ローテーション）"
      elsif env_path.present?
        "環境変数ADMIN_PATH"
      else
        "デフォルト値"
      end
    Rails.logger.info("[AdminPath] 管理画面パスの決定元: #{source}")

    if db_path.present? && env_path.present? && db_path != env_path
      Rails.logger.warn(
        "[AdminPath] DB履歴と環境変数ADMIN_PATHの値が異なります。DB履歴が優先されます" \
        "（ENV側を有効にするには admin_path_histories を削除してください）"
      )
    end
  rescue StandardError => e
    # DB未作成（初回セットアップ等）でも起動を妨げない
    Rails.logger.warn("[AdminPath] 決定元の確認をスキップ: #{e.class}")
  end
end
