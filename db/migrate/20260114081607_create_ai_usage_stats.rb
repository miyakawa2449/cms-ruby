class CreateAiUsageStats < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_usage_stats do |t|
      t.date :date, null: false
      t.string :ai_model, null: false
      t.integer :total_requests, default: 0
      t.integer :total_tokens, default: 0
      t.decimal :total_cost, precision: 10, scale: 2, default: 0
      t.jsonb :breakdown, default: {}  # Function-specific breakdown

      t.timestamps
    end

    add_index :ai_usage_stats, [:date, :ai_model], unique: true
    add_index :ai_usage_stats, :date
  end
end
