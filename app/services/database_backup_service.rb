class DatabaseBackupService
  attr_reader :backup_type, :timestamp

  def initialize(backup_type)
    @backup_type = backup_type
    @timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
  end

  def execute
    ensure_backup_dir
    dump_file = create_dump
    compressed_file = compress_dump(dump_file)
    log_checksum(compressed_file)
    compressed_file
  end

  private

  def ensure_backup_dir
    FileUtils.mkdir_p(backup_dir)
  end

  def create_dump
    dump_file = temp_file_path("database", "dump")
    db_config = ActiveRecord::Base.connection_db_config.configuration_hash

    command = build_pg_dump_command(db_config, dump_file)
    env = { "PGPASSWORD" => db_config[:password].to_s }

    success = system(env, *command)

    unless success && $?.success?
      raise "Database dump failed with exit code #{$?.exitstatus}"
    end

    dump_file
  end

  def build_pg_dump_command(db_config, dump_file)
    cmd = [ "pg_dump", "-Fc", "-f", dump_file ]
    cmd += [ "-h", db_config[:host] ] if db_config[:host].present?
    cmd += [ "-p", db_config[:port].to_s ] if db_config[:port].present?
    cmd += [ "-U", db_config[:username] ] if db_config[:username].present?
    cmd += [ "-d", db_config[:database] ]
    cmd
  end

  def compress_dump(dump_file)
    compressed_file = "#{dump_file}.gz"

    Zlib::GzipWriter.open(compressed_file) do |gz|
      gz.write(File.binread(dump_file))
    end

    File.delete(dump_file)
    compressed_file
  end

  def log_checksum(file)
    checksum = Digest::SHA256.file(file).hexdigest
    Rails.logger.info("DatabaseBackupService: checksum=#{checksum} file=#{File.basename(file)}")
    checksum
  end

  def temp_file_path(category, extension)
    File.join(backup_dir, "#{category}_#{timestamp}_#{backup_type}.#{extension}")
  end

  def backup_dir
    Rails.root.join("tmp", "backup").to_s
  end
end
