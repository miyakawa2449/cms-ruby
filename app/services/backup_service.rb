class BackupService
  MAX_UPLOAD_RETRIES = 3

  attr_reader :backup_type, :backup_log

  def initialize(backup_type:)
    @backup_type = backup_type
    @temp_files = []
  end

  def execute
    @backup_log = BackupLog.create!(
      backup_type: backup_type,
      status: :in_progress,
      started_at: Time.current
    )

    s3_keys = []
    s3_keys << run_and_upload(:database)
    s3_keys << run_and_upload(:storage)
    s3_keys << run_and_upload(:config)

    cleanup_old_backups

    total_size = S3Service.new.get_latest_backup_size(backup_type)
    backup_log.update!(
      status: :success,
      completed_at: Time.current,
      file_size: total_size,
      s3_keys: s3_keys.compact
    )

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

  def run_and_upload(category)
    service_class = {
      database: DatabaseBackupService,
      storage: StorageBackupService,
      config: ConfigBackupService
    }.fetch(category)

    file_path = service_class.new(backup_type).execute
    @temp_files << file_path
    upload_with_retry(file_path: file_path, category: category.to_s)
  end

  def upload_with_retry(file_path:, category:)
    retries = 0
    begin
      S3Service.new.upload(
        file_path: file_path,
        backup_type: backup_type,
        category: category
      )
    rescue Aws::S3::Errors::ServiceError => e
      retries += 1
      if retries < MAX_UPLOAD_RETRIES
        wait = 2**retries
        Rails.logger.warn(
          "BackupService: S3 upload failed (attempt #{retries}/#{MAX_UPLOAD_RETRIES}) " \
          "category=#{category} error=#{e.message} retrying in #{wait}s"
        )
        sleep(wait)
        retry
      else
        Rails.logger.error(
          "BackupService: S3 upload failed after #{MAX_UPLOAD_RETRIES} attempts category=#{category}"
        )
        raise
      end
    end
  end

  def cleanup_old_backups
    S3RetentionManager.new(backup_type).cleanup
  rescue => e
    Rails.logger.warn("BackupService: retention cleanup failed error=#{e.message}")
  end

  def notify_success
    BackupMailer.backup_success(backup_log).deliver_later
    SlackNotifier.notify_backup_status(backup_log)
  rescue => e
    Rails.logger.warn("BackupService: notification failed error=#{e.message}")
  end

  def notify_failure(error)
    BackupMailer.backup_failed(backup_log, error).deliver_later
    SlackNotifier.notify_backup_status(backup_log)
  rescue => e
    Rails.logger.warn("BackupService: failure notification error=#{e.message}")
  end

  def cleanup_temp_files
    @temp_files.each do |file|
      File.delete(file) if file && File.exist?(file)
    end
  end
end
