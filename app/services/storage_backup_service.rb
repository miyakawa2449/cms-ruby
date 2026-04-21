class StorageBackupService
  attr_reader :backup_type, :timestamp

  def initialize(backup_type)
    @backup_type = backup_type
    @timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
  end

  def execute
    ensure_backup_dir
    storage_dir = Rails.root.join("storage").to_s

    unless Dir.exist?(storage_dir)
      Rails.logger.warn("StorageBackupService: storage/ directory not found, creating empty archive")
      FileUtils.mkdir_p(storage_dir)
    end

    archive_file = create_archive(storage_dir)
    log_checksum(archive_file)
    archive_file
  end

  private

  def ensure_backup_dir
    FileUtils.mkdir_p(backup_dir)
  end

  def create_archive(storage_dir)
    archive_file = temp_file_path("storage", "tar.gz")

    success = system("tar", "-czf", archive_file, "-C", Rails.root.to_s, "storage")

    unless success && $?.success?
      raise "Storage archive failed with exit code #{$?.exitstatus}"
    end

    archive_file
  end

  def log_checksum(file)
    checksum = Digest::SHA256.file(file).hexdigest
    Rails.logger.info("StorageBackupService: checksum=#{checksum} file=#{File.basename(file)}")
    checksum
  end

  def temp_file_path(category, extension)
    File.join(backup_dir, "#{category}_#{timestamp}_#{backup_type}.#{extension}")
  end

  def backup_dir
    Rails.root.join("tmp", "backup").to_s
  end
end
