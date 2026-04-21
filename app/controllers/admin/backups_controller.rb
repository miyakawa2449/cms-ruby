class Admin::BackupsController < Admin::BaseController
  def index
    @backup_type = params[:backup_type].presence
    @backups = fetch_backups
    @backup_logs = BackupLog.recent.limit(20)
  end

  def restore
    backup_key = params[:backup_key].to_s.strip

    if backup_key.blank?
      redirect_to admin_backups_path, alert: "バックアップキーが指定されていません。"
      return
    end

    backup_keys = resolve_backup_keys(backup_key)
    Restore::RestoreJob.perform_later(backup_keys.stringify_keys)

    redirect_to admin_backups_path,
      notice: "復元ジョブをキューに追加しました。完了後にメール通知が届きます。"
  rescue => e
    Rails.logger.error("Admin::BackupsController#restore: error=#{e.message}")
    redirect_to admin_backups_path, alert: "復元の開始に失敗しました: #{e.message}"
  end

  private

  def fetch_backups
    backups = S3Service.new.list_backups(backup_type: @backup_type)
    backups.sort_by { |b| b[:last_modified] }.reverse
  rescue => e
    Rails.logger.error("Admin::BackupsController: failed to fetch backups error=#{e.message}")
    flash.now[:alert] = "バックアップ一覧の取得に失敗しました: #{e.message}"
    []
  end

  # S3キー（例: "daily/2026/04/20/database_file.dump.gz"）から
  # 同日同タイプの database/storage/config キーを検索して返す
  def resolve_backup_keys(backup_key)
    parts = backup_key.split("/")
    # parts: ["daily", "2026", "04", "20", "database_file.dump.gz"]
    date_prefix = parts[0..3].join("/") + "/"

    candidates = S3Service.new.list_backups(backup_type: parts[0])
    day_files = candidates.select { |b| b[:key].start_with?(date_prefix) }

    {
      database: find_category_key(day_files, "database"),
      storage:  find_category_key(day_files, "storage"),
      config:   find_category_key(day_files, "config")
    }
  end

  def find_category_key(files, category)
    entry = files.find { |b| File.basename(b[:key]).start_with?("#{category}_") }
    entry&.dig(:key)
  end
end
