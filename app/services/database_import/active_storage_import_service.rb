# frozen_string_literal: true

module DatabaseImport
  # Restores Active Storage files from extracted ZIP contents
  class ActiveStorageImportService
    def initialize(extracted_storage_path)
      @extracted_storage_path = extracted_storage_path
      @target_storage_path = Rails.root.join("storage")
    end

    # Execute the file restoration
    # @return [Boolean] true if successful
    def call
      Rails.logger.info "[ActiveStorageImport] Starting Active Storage import..."

      unless storage_directory_exists?
        Rails.logger.info "[ActiveStorageImport] No storage directory found in export, skipping"
        return true
      end

      backup_existing_storage
      restore_storage_files
      log_import_summary

      Rails.logger.info "[ActiveStorageImport] Import completed successfully"
      true
    rescue StandardError => e
      Rails.logger.error "[ActiveStorageImport] Import failed: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      raise
    end

    private

    def storage_directory_exists?
      File.directory?(@extracted_storage_path)
    end

    def backup_existing_storage
      return unless File.directory?(@target_storage_path)

      # Count existing files
      existing_count = count_files(@target_storage_path)
      return if existing_count.zero?

      # Create backup directory
      backup_path = "#{@target_storage_path}_backup_#{Time.current.strftime('%Y%m%d_%H%M%S')}"
      FileUtils.mv(@target_storage_path, backup_path)

      Rails.logger.info "[ActiveStorageImport] Backed up existing storage (#{existing_count} files) to: #{backup_path}"
    end

    def restore_storage_files
      Rails.logger.info "[ActiveStorageImport] Restoring files from #{@extracted_storage_path} to #{@target_storage_path}"

      FileUtils.mkdir_p(@target_storage_path)
      FileUtils.cp_r(Dir.glob("#{@extracted_storage_path}/*"), @target_storage_path)
    end

    def log_import_summary
      file_count = count_files(@target_storage_path)
      total_size = calculate_directory_size(@target_storage_path)

      Rails.logger.info "[ActiveStorageImport] Restored #{file_count} files (#{format_size(total_size)})"
    end

    def count_files(directory)
      return 0 unless File.directory?(directory)

      Dir.glob("#{directory}/**/*").count { |f| File.file?(f) }
    end

    def calculate_directory_size(directory)
      return 0 unless File.directory?(directory)

      Dir.glob("#{directory}/**/*").sum { |f| File.file?(f) ? File.size(f) : 0 }
    end

    def format_size(bytes)
      return "0 B" if bytes.zero?

      units = %w[B KB MB GB]
      exp = (Math.log(bytes) / Math.log(1024)).to_i
      exp = units.size - 1 if exp >= units.size

      format("%.2f %s", bytes.to_f / 1024**exp, units[exp])
    end
  end
end
