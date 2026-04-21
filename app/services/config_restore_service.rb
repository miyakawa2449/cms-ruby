class ConfigRestoreService
  def initialize(file_path)
    @file_path = file_path
  end

  def execute
    staging_dir = Rails.root.join("tmp", "restore", "config_staging_#{Time.current.to_i}").to_s
    FileUtils.mkdir_p(staging_dir)

    begin
      extract_archive(staging_dir)
      restore_files(staging_dir)
    ensure
      FileUtils.rm_rf(staging_dir)
    end

    Rails.logger.info("ConfigRestoreService: restore completed file=#{File.basename(@file_path)}")
  end

  private

  def extract_archive(staging_dir)
    success = system("tar", "-xzf", @file_path, "-C", staging_dir)

    unless success && $?.success?
      raise "Config extract failed with exit code #{$?.exitstatus}"
    end
  end

  def restore_files(staging_dir)
    Dir.glob(File.join(staging_dir, "**", "*"), File::FNM_DOTMATCH).each do |source|
      next if File.directory?(source)

      relative = source.sub("#{staging_dir}/", "")
      dest = Rails.root.join(relative).to_s

      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.cp(source, dest)
      Rails.logger.info("ConfigRestoreService: restored #{relative}")
    end
  end
end
