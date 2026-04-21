class DatabaseRestoreService
  def initialize(file_path)
    @file_path = file_path
  end

  def execute
    decompressed_file = decompress
    restore_database(decompressed_file)
  ensure
    File.delete(decompressed_file) if decompressed_file && File.exist?(decompressed_file)
  end

  private

  def decompress
    decompressed = @file_path.sub(/\.gz\z/, "")

    Zlib::GzipReader.open(@file_path) do |gz|
      File.binwrite(decompressed, gz.read)
    end

    decompressed
  end

  def restore_database(dump_file)
    db_config = ActiveRecord::Base.connection_db_config.configuration_hash

    command = build_pg_restore_command(db_config, dump_file)
    env = { "PGPASSWORD" => db_config[:password].to_s }

    success = system(env, *command)

    unless success && $?.success?
      raise "Database restore failed with exit code #{$?.exitstatus}"
    end

    Rails.logger.info("DatabaseRestoreService: restore completed file=#{File.basename(@file_path)}")
  end

  def build_pg_restore_command(db_config, dump_file)
    cmd = [ "pg_restore", "--clean", "--if-exists", "-d", db_config[:database] ]
    cmd += [ "-h", db_config[:host] ] if db_config[:host].present?
    cmd += [ "-p", db_config[:port].to_s ] if db_config[:port].present?
    cmd += [ "-U", db_config[:username] ] if db_config[:username].present?
    cmd << dump_file
    cmd
  end
end
