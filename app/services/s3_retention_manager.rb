class S3RetentionManager
  RETENTION_DAYS = {
    "daily" => 7,
    "weekly" => 28,
    "monthly" => 365
  }.freeze

  attr_reader :backup_type, :s3_service

  def initialize(backup_type)
    @backup_type = backup_type
    @s3_service = S3Service.new
  end

  def cleanup
    retention_days = RETENTION_DAYS[backup_type]

    unless retention_days
      Rails.logger.warn("S3RetentionManager: unknown backup_type=#{backup_type}, skipping cleanup")
      return
    end

    cutoff = retention_days.days.ago
    old_backups = find_old_backups(cutoff)

    deleted_count = 0
    old_backups.each do |backup|
      delete_with_rescue(backup)
      deleted_count += 1
    end

    Rails.logger.info(
      "S3RetentionManager: cleanup completed backup_type=#{backup_type} " \
      "deleted=#{deleted_count} cutoff=#{cutoff.iso8601}"
    )
  end

  private

  def find_old_backups(cutoff)
    s3_service.list_backups(backup_type: backup_type).select do |backup|
      backup[:last_modified] < cutoff
    end
  end

  def delete_with_rescue(backup)
    s3_service.delete(object_key: backup[:key])
    Rails.logger.info("S3RetentionManager: deleted key=#{backup[:key]}")
  rescue => e
    Rails.logger.warn("S3RetentionManager: failed to delete key=#{backup[:key]} error=#{e.message}")
  end
end
