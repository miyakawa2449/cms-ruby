module Backup
  class DailyBackupJob < ApplicationJob
    queue_as :backup

    def perform
      BackupService.new(backup_type: "daily").execute
    end
  end
end
