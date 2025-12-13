ActiveRecord::Base.connection.execute("DELETE FROM schema_migrations WHERE version = '000'")
puts 'Removed invalid migration record'