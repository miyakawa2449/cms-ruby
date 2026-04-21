class StorageRestoreService
  def initialize(file_path)
    @file_path = file_path
  end

  def execute
    # The backup archive has paths starting with "storage/".
    # Extract to Rails.root so files land at Rails.root/storage/...
    rails_root = Rails.root.to_s
    FileUtils.mkdir_p(File.join(rails_root, "storage"))

    success = system("tar", "-xzf", @file_path, "-C", rails_root)

    unless success && $?.success?
      raise "Storage restore failed with exit code #{$?.exitstatus}"
    end

    Rails.logger.info("StorageRestoreService: restore completed file=#{File.basename(@file_path)}")
  end
end
