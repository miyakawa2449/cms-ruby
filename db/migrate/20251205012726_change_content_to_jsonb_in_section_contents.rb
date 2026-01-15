class ChangeContentToJsonbInSectionContents < ActiveRecord::Migration[8.1]
  def up
    # 古いカラムを削除
    remove_column :section_contents, :content

    # 新しいJSONBカラムを追加
    add_column :section_contents, :content, :jsonb, default: {}, null: false

    # インデックスを追加
    add_index :section_contents, :content, using: :gin
  end

  def down
    remove_index :section_contents, :content if index_exists?(:section_contents, :content)

    # 一時カラムを追加
    add_column :section_contents, :content_text, :text

    # JSONBからテキストへ変換
    SectionContent.reset_column_information
    SectionContent.find_each do |sc|
      sc.update_columns(content_text: sc.content.to_json) if sc.content.present?
    end

    # カラムの入れ替え
    remove_column :section_contents, :content
    rename_column :section_contents, :content_text, :content
  end
end
