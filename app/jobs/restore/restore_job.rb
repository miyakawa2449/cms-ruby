module Restore
  class RestoreJob < ApplicationJob
    queue_as :backup

    def perform(backup_keys)
      RestoreService.new(backup_keys: backup_keys.symbolize_keys).execute
    end
  end
end
