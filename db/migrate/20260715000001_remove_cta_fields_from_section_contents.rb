class RemoveCtaFieldsFromSectionContents < ActiveRecord::Migration[8.1]
  # My Story独立ページ廃止に伴い、同ページへ誘導していたCTAフィールドを削除
  # （heroセクション用の cta_primary_* / cta_secondary_* は別物のため残す）
  def change
    remove_column :section_contents, :cta_button_text, :string
    remove_column :section_contents, :cta_description, :text
  end
end
