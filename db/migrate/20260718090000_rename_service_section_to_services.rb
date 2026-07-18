class RenameServiceSectionToServices < ActiveRecord::Migration[8.1]
  # ナビ・フッターのアンカー（#services）とセクションid（= sections.name）を
  # 一致させるため 'service' を 'services' へ改名（2026-07-18 剛さん判断）。
  # パーシャルも _services.html.erb へ同時にリネームしている。
  #
  # 2026-07-15の本番障害（service/services並存×パーシャル不一致で500）の教訓として、
  # 並存を検出した場合は自動統合せず明示的に失敗させる（手動整理が必要）。
  def up
    service_id = select_value("SELECT id FROM sections WHERE name = 'service'")
    return if service_id.nil?

    if select_value("SELECT 1 FROM sections WHERE name = 'services'")
      raise <<~MSG
        sections 'service' と 'services' が並存しています。
        どちらを残すか手動で整理してからマイグレーションを再実行してください。
      MSG
    end

    execute("UPDATE sections SET name = 'services' WHERE id = #{service_id.to_i}")
  end

  def down
    services_id = select_value("SELECT id FROM sections WHERE name = 'services'")
    return if services_id.nil?
    return if select_value("SELECT 1 FROM sections WHERE name = 'service'")

    execute("UPDATE sections SET name = 'service' WHERE id = #{services_id.to_i}")
  end
end
