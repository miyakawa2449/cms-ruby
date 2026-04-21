module Backup
  class WeeklyBackupJob < ApplicationJob
    queue_as :backup

    def perform
      BackupService.new(backup_type: "weekly").execute
    end
  end
end
