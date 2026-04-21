class ConfigBackupService
  attr_reader :backup_type, :timestamp

  REQUIRED_FILES = [
    ".env",
    "config/credentials.yml.enc"
  ].freeze

  OPTIONAL_FILES = [
    ".env.production",
    "config/master.key"
  ].freeze

  def initialize(backup_type)
    @backup_type = backup_type
    @timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
  end

  def execute
    ensure_backup_dir
    validate_required_files
    archive_file = create_archive
    log_checksum(archive_file)
    archive_file
  end

  private

  def ensure_backup_dir
    FileUtils.mkdir_p(backup_dir)
  end

  def validate_required_files
    missing = REQUIRED_FILES.reject { |f| File.exist?(Rails.root.join(f)) }
    raise "Required config files missing: #{missing.join(', ')}" if missing.any?
  end

  def create_archive
    archive_file = temp_file_path("config", "tar.gz")
    staging_dir = Rails.root.join("tmp", "backup", "config_staging_#{timestamp}").to_s

    FileUtils.mkdir_p(staging_dir)

    begin
      copy_files_to_staging(staging_dir)
      build_archive(archive_file, staging_dir)
    ensure
      FileUtils.rm_rf(staging_dir)
    end

    archive_file
  end

  def copy_files_to_staging(staging_dir)
    (REQUIRED_FILES + OPTIONAL_FILES).each do |relative_path|
      source = Rails.root.join(relative_path).to_s
      next unless File.exist?(source)

      # Preserve subdirectory structure within staging dir
      dest = File.join(staging_dir, relative_path)
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.cp(source, dest)
    end
  end

  def build_archive(archive_file, staging_dir)
    success = system("tar", "-czf", archive_file, "-C", staging_dir, ".")

    unless success && $?.success?
      raise "Config archive failed with exit code #{$?.exitstatus}"
    end
  end

  def log_checksum(file)
    checksum = Digest::SHA256.file(file).hexdigest
    Rails.logger.info("ConfigBackupService: checksum=#{checksum} file=#{File.basename(file)}")
    checksum
  end

  def temp_file_path(category, extension)
    File.join(backup_dir, "#{category}_#{timestamp}_#{backup_type}.#{extension}")
  end

  def backup_dir
    Rails.root.join("tmp", "backup").to_s
  end
end
