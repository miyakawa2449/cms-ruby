class RenameServicesSectionToService < ActiveRecord::Migration[8.1]
  # 旧init_sections.rbが投入した'services'をseeds.rbの'service'へ統一（監査C-3）
  # パーシャルは _service.html.erb にリネーム済みで、セクション名と一致する
  def up
    execute <<~SQL
      UPDATE sections SET name = 'service'
      WHERE name = 'services'
        AND NOT EXISTS (SELECT 1 FROM sections s2 WHERE s2.name = 'service')
    SQL
  end

  def down
    # 統一後の名前を維持する（元のゆらぎに戻す意味がないため何もしない）
  end
end
