class FixDuplicateServiceSections < ActiveRecord::Migration[8.1]
  # 2026-07-15本番障害の再発防止（古いバックアップからのリストア環境も自動修復する）。
  #
  # 経緯: 旧init_sections.rbが'services'を、seeds.rbが'service'を作成し両方が並存。
  # 20260715000003のガード条件（'service'が既に存在すればリネームしない）が
  # この並存パターンで裏目に出て、実コンテンツ入りの'services'が残置され、
  # パーシャル（_service.html.erb）不在でトップページが500になった。
  #
  # 対処: 空の'service'を削除してから'services'を'service'へリネームする。
  # 両方にコンテンツがある場合は自動判断せず明示的に失敗させる（手動統合が必要）。
  def up
    services_id = select_value("SELECT id FROM sections WHERE name = 'services'")
    return if services_id.nil?

    service_id = select_value("SELECT id FROM sections WHERE name = 'service'")

    if service_id
      service_has_content = select_value(
        "SELECT 1 FROM section_contents WHERE section_id = #{service_id.to_i} LIMIT 1"
      )
      if service_has_content
        raise <<~MSG
          sections 'service'(id=#{service_id}) と 'services'(id=#{services_id}) の
          両方にsection_contentsが存在します。自動統合できないため、
          どちらを残すか手動で整理してからマイグレーションを再実行してください。
        MSG
      end

      execute("DELETE FROM sections WHERE id = #{service_id.to_i}")
    end

    execute("UPDATE sections SET name = 'service' WHERE id = #{services_id.to_i}")
  end

  def down
    # 並存状態に戻す意味がないため何もしない
  end
end
