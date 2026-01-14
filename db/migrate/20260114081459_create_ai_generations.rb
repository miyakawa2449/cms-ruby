class CreateAiGenerations < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_generations do |t|
      t.references :article, foreign_key: true
      t.references :admin_user, foreign_key: true
      t.string :generation_type, null: false  # 'summary', 'tags', 'slug', 'seo_meta', 'structure'
      t.text :input_content
      t.jsonb :output_data, default: {}
      t.string :model_used
      t.integer :tokens_used, default: 0
      t.decimal :cost, precision: 10, scale: 6, default: 0
      t.string :status, default: 'pending'  # 'pending', 'completed', 'failed'
      t.text :error_message

      t.timestamps
    end

    add_index :ai_generations, :generation_type
    add_index :ai_generations, :status
    add_index :ai_generations, :created_at
  end
end
