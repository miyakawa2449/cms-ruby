class CreateAccessLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :access_logs do |t|
      # Request information
      t.string :method, null: false, limit: 10
      t.string :path, null: false, limit: 2000
      t.string :query_string, limit: 2000
      t.string :controller_action, limit: 100
      
      # Response information
      t.integer :status_code, null: false
      t.decimal :response_time, precision: 10, scale: 3
      t.bigint :response_size
      
      # Client information
      t.inet :ip_address
      t.string :user_agent, limit: 1000
      t.string :referer, limit: 2000
      t.string :accept_language, limit: 100
      
      # Geographic data
      t.string :country_code, limit: 2
      t.string :region, limit: 100
      t.string :city, limit: 100
      
      # Device information
      t.string :device_type, limit: 20
      t.string :browser, limit: 50
      t.string :browser_version, limit: 20
      t.string :os, limit: 50
      t.string :os_version, limit: 20
      
      # Content information
      t.string :content_type, limit: 100
      t.string :content_encoding, limit: 20
      
      # Authentication
      t.references :admin_user, null: true, foreign_key: true
      t.string :session_id, limit: 100
      
      # Bot detection
      t.boolean :is_bot, default: false, null: false
      t.string :bot_name, limit: 50
      
      # Additional data
      t.json :request_headers, default: {}
      t.json :custom_data, default: {}
      
      # Partitioning column (for date-based partitioning)
      t.date :log_date, null: false
      
      t.timestamp :timestamp, null: false, default: -> { 'CURRENT_TIMESTAMP' }
    end

    # Indexes
    add_index :access_logs, :timestamp
    add_index :access_logs, :log_date
    add_index :access_logs, :ip_address
    add_index :access_logs, :path
    add_index :access_logs, :method
    add_index :access_logs, :status_code
    add_index :access_logs, :controller_action
    add_index :access_logs, :admin_user_id
    add_index :access_logs, :is_bot
    add_index :access_logs, :country_code
    add_index :access_logs, :device_type
    add_index :access_logs, :browser
    
    # Composite indexes
    add_index :access_logs, [:log_date, :timestamp], name: 'index_access_logs_date_time'
    add_index :access_logs, [:path, :log_date], name: 'index_access_logs_path_date'
    add_index :access_logs, [:ip_address, :log_date], name: 'index_access_logs_ip_date'
    add_index :access_logs, [:status_code, :log_date], name: 'index_access_logs_status_date'
    add_index :access_logs, [:admin_user_id, :log_date], name: 'index_access_logs_user_date'
    add_index :access_logs, [:is_bot, :log_date], name: 'index_access_logs_bot_date'
    add_index :access_logs, [:country_code, :log_date], name: 'index_access_logs_country_date'
    
    # Performance indexes
    add_index :access_logs, [:response_time, :log_date], where: "response_time > 1000", name: 'index_access_logs_slow_requests'
    add_index :access_logs, [:status_code, :log_date], where: "status_code >= 400", name: 'index_access_logs_errors'
    add_index :access_logs, [:log_date, :timestamp], where: "is_bot = false", name: 'index_access_logs_human_traffic'
    
    # Full-text search indexes
    add_index :access_logs, :path, opclass: :gin_trgm_ops, using: :gin, name: 'index_access_logs_path_trgm'
    add_index :access_logs, :user_agent, opclass: :gin_trgm_ops, using: :gin, name: 'index_access_logs_user_agent_trgm'
    
    # JSONB indexes
    add_index :access_logs, :request_headers, using: :gin, name: 'index_access_logs_headers_gin'
    add_index :access_logs, :custom_data, using: :gin, name: 'index_access_logs_custom_data_gin'
    
    # Constraints
    add_check_constraint :access_logs, "method IN ('GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'HEAD', 'OPTIONS')", name: 'access_logs_valid_method'
    add_check_constraint :access_logs, "status_code >= 100 AND status_code <= 599", name: 'access_logs_valid_status_code'
    add_check_constraint :access_logs, "response_time >= 0 OR response_time IS NULL", name: 'access_logs_response_time_positive'
    add_check_constraint :access_logs, "response_size >= 0 OR response_size IS NULL", name: 'access_logs_response_size_positive'
    add_check_constraint :access_logs, "device_type IN ('desktop', 'mobile', 'tablet', 'bot', 'unknown') OR device_type IS NULL", name: 'access_logs_valid_device_type'
    add_check_constraint :access_logs, "length(country_code) = 2 OR country_code IS NULL", name: 'access_logs_country_code_format'
    add_check_constraint :access_logs, "log_date = date(timestamp)", name: 'access_logs_date_consistency'
    
    # Add comment for partitioning
    execute <<-SQL
      COMMENT ON TABLE access_logs IS 'Partitioned by log_date for performance and maintenance';
      COMMENT ON COLUMN access_logs.log_date IS 'Partitioning column - must match date(timestamp)';
    SQL
  end
end