module Backup
  class MonthlyBackupJob < ApplicationJob
    queue_as :backup

    def perform
      BackupService.new(backup_type: "monthly").execute
    end
  end
end
