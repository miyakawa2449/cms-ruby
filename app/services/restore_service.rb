class RestoreService
  attr_reader :backup_keys, :backup_log

  def initialize(backup_keys:)
    @backup_keys = backup_keys  # { database: "s3/key", storage: "s3/key", config: "s3/key" }
    @temp_files = []
  end

  def execute
    @backup_log = BackupLog.create!(
      backup_type: :restore,
      status: :in_progress,
      started_at: Time.current
    )

    database_file = download(backup_keys[:database])
    storage_file  = download(backup_keys[:storage])
    config_file   = download(backup_keys[:config])

    DatabaseRestoreService.new(database_file).execute if database_file
    StorageRestoreService.new(storage_file).execute   if storage_file
    ConfigRestoreService.new(config_file).execute     if config_file

    backup_log.update!(status: :success, completed_at: Time.current)
    notify_success
  rescue => e
    backup_log&.update!(
      status: :failed,
      completed_at: Time.current,
      error_message: e.message
    )
    notify_failure(e)
    raise
  ensure
    cleanup_temp_files
  end

  private

  def download(object_key)
    return nil if object_key.blank?

    dest = Rails.root.join("tmp", "restore", File.basename(object_key)).to_s
    FileUtils.mkdir_p(File.dirname(dest))

    S3Service.new.download(object_key: object_key, destination: dest)
    @temp_files << dest
    dest
  end

  def notify_success
    BackupMailer.restore_success(backup_log).deliver_later
  rescue => e
    Rails.logger.warn("RestoreService: notification failed error=#{e.message}")
  end

  def notify_failure(error)
    BackupMailer.restore_failed(backup_log, error).deliver_later
  rescue => e
    Rails.logger.warn("RestoreService: failure notification error=#{e.message}")
  end

  def cleanup_temp_files
    @temp_files.each do |file|
      File.delete(file) if file && File.exist?(file)
    end
  end
end
