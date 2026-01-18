# frozen_string_literal: true

module DatabaseExport
  # Copies Active Storage files to a temporary directory for export
  class ActiveStorageExportService
    def initialize(temp_dir)
      @temp_dir = temp_dir
      @storage_path = Rails.root.join("storage")
      @target_path = File.join(@temp_dir, "storage")
    end

    # Execute the file copy
    # @return [Boolean] true if successful
    def call
      Rails.logger.info "[ActiveStorageExport] Starting Active Storage export..."

      unless storage_directory_exists?
        Rails.logger.warn "[ActiveStorageExport] Storage directory not found: #{@storage_path}"
        return true # Not an error - just no files to export
      end

      copy_storage_files
      log_export_summary

      Rails.logger.info "[ActiveStorageExport] Export completed successfully"
      true
    rescue StandardError => e
      Rails.logger.error "[ActiveStorageExport] Export failed: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      raise
    end

    private

    def storage_directory_exists?
      File.directory?(@storage_path)
    end

    def copy_storage_files
      Rails.logger.info "[ActiveStorageExport] Copying from #{@storage_path} to #{@target_path}"

      FileUtils.mkdir_p(@target_path)
      FileUtils.cp_r(Dir.glob("#{@storage_path}/*"), @target_path)
    end

    def log_export_summary
      file_count = count_files(@target_path)
      total_size = calculate_directory_size(@target_path)

      Rails.logger.info "[ActiveStorageExport] Copied #{file_count} files (#{format_size(total_size)})"
    end

    def count_files(directory)
      Dir.glob("#{directory}/**/*").count { |f| File.file?(f) }
    end

    def calculate_directory_size(directory)
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
