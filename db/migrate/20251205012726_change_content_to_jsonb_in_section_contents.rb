class ChangeContentToJsonbInSectionContents < ActiveRecord::Migration[8.1]
  def up
    # 一時カラムを追加
    add_column :section_contents, :content_jsonb, :jsonb, default: {}, null: false
    
    # 既存データの移行
    execute <<-SQL
      UPDATE section_contents 
      SET content_jsonb = '{}'::jsonb 
      WHERE content IS NULL OR content = '';
    SQL
    
    # Ruby形式の文字列データを持つレコードがある場合はRubyコードで処理
    SectionContent.reset_column_information
    SectionContent.where.not(content: [nil, '']).find_each do |sc|
      begin
        # Rubyハッシュ形式の文字列をJSONに変換
        if sc.content.include?('=>')
          # Ruby形式のハッシュ（例：{key: value}）
          content_str = sc.content
            .gsub(/(\w+):\s*/, '"\1": ')  # シンボルキーを文字列キーに
            .gsub('=>', ':')              # ハッシュロケット記法を変換
          
          parsed_content = JSON.parse(content_str)
        else
          # 既にJSON形式の場合
          parsed_content = JSON.parse(sc.content)
        end
        
        sc.update_columns(content_jsonb: parsed_content)
        puts "Migrated content for SectionContent ID #{sc.id}"
      rescue => e
        puts "Migration warning for ID #{sc.id}: #{e.message}"
        # エラーの場合は空のハッシュを設定
        sc.update_columns(content_jsonb: {})
      end
    end
    
    # 古いカラムを削除
    remove_column :section_contents, :content
    
    # 新しいカラムをリネーム
    rename_column :section_contents, :content_jsonb, :content
    
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