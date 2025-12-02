class CreateAccessLogs < ActiveRecord::Migration[8.0]
  def up
    # パーティション親テーブル
    execute <<-SQL
      CREATE TABLE access_logs (
        id BIGSERIAL,
        path VARCHAR(500) NOT NULL,
        method VARCHAR(10) NOT NULL,
        status_code INTEGER,
        ip_address INET,
        user_agent TEXT,
        referrer VARCHAR(500),
        response_time INTEGER,
        admin_user_id BIGINT,
        session_id VARCHAR(255),
        created_at TIMESTAMP NOT NULL DEFAULT NOW(),
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);
    SQL
    
    # 初期パーティション作成（現在月）
    current_month = Date.current.beginning_of_month
    next_month = current_month.next_month
    partition_name = "access_logs_#{current_month.strftime('%Y_%m')}"
    
    execute <<-SQL
      CREATE TABLE #{partition_name} PARTITION OF access_logs
      FOR VALUES FROM ('#{current_month}') TO ('#{next_month}');
    SQL
    
    # パーティション用インデックス
    add_index partition_name, :created_at
    add_index partition_name, :path
    add_index partition_name, :admin_user_id
    
    # 外部キー制約（パーティション子テーブルに追加）
    execute <<-SQL
      ALTER TABLE #{partition_name} 
      ADD CONSTRAINT fk_#{partition_name}_admin_user 
      FOREIGN KEY (admin_user_id) REFERENCES admin_users(id);
    SQL
  end
  
  def down
    drop_table :access_logs
  end
end
