# frozen_string_literal: true

require "zip"

module DatabaseImport
  # Extracts and validates uploaded ZIP files for import
  class ZipExtractorService
    class InvalidZipError < StandardError; end
    class MissingDataJsonError < StandardError; end

    def initialize(zip_file_path)
      @zip_file_path = zip_file_path
      @temp_dir = nil
    end

    # Extract ZIP file and validate contents
    # @return [String] Path to the extracted temporary directory
    # @raise [InvalidZipError] if ZIP file is invalid
    # @raise [MissingDataJsonError] if data.json is missing
    def call
      Rails.logger.info "[ZipExtractor] Starting ZIP extraction: #{@zip_file_path}"

      validate_zip_file
      @temp_dir = Dir.mktmpdir("database_import")
      extract_zip
      validate_contents

      Rails.logger.info "[ZipExtractor] Extraction completed: #{@temp_dir}"

      @temp_dir
    rescue StandardError => e
      # Clean up temp directory on failure
      cleanup_temp_dir
      Rails.logger.error "[ZipExtractor] Extraction failed: #{e.message}"
      raise
    end

    # Clean up the temporary directory
    def cleanup
      cleanup_temp_dir
    end

    private

    def validate_zip_file
      unless File.exist?(@zip_file_path)
        raise InvalidZipError, "ZIPファイルが見つかりません: #{@zip_file_path}"
      end

      unless File.size(@zip_file_path) > 0
        raise InvalidZipError, "ZIPファイルが空です"
      end

      # Verify it's a valid ZIP file
      begin
        Zip::File.open(@zip_file_path) { |_| }
      rescue Zip::Error => e
        raise InvalidZipError, "無効なZIPファイルです: #{e.message}"
      end
    end

    def extract_zip
      Rails.logger.info "[ZipExtractor] Extracting to: #{@temp_dir}"

      entry_count = 0
      Zip::File.open(@zip_file_path) do |zipfile|
        zipfile.each do |entry|
          entry_path = File.join(@temp_dir, entry.name)

          # Security: Prevent path traversal attacks
          unless entry_path.start_with?(@temp_dir)
            raise InvalidZipError, "不正なファイルパスが含まれています: #{entry.name}"
          end

          if entry.directory?
            FileUtils.mkdir_p(entry_path)
          else
            FileUtils.mkdir_p(File.dirname(entry_path))
            entry.extract(entry_path)
          end
          entry_count += 1
        end
      end

      Rails.logger.info "[ZipExtractor] Extracted #{entry_count} entries"
    end

    def validate_contents
      data_json_path = File.join(@temp_dir, "data.json")

      unless File.exist?(data_json_path)
        raise MissingDataJsonError, "data.jsonファイルが見つかりません"
      end

      # Validate JSON is parseable
      begin
        JSON.parse(File.read(data_json_path))
      rescue JSON::ParserError => e
        raise InvalidZipError, "data.jsonの形式が不正です: #{e.message}"
      end

      Rails.logger.info "[ZipExtractor] Contents validated successfully"

      # Check for storage directory (optional - not required)
      storage_path = File.join(@temp_dir, "storage")
      if File.directory?(storage_path)
        file_count = Dir.glob("#{storage_path}/**/*").count { |f| File.file?(f) }
        Rails.logger.info "[ZipExtractor] Storage directory found with #{file_count} files"
      else
        Rails.logger.info "[ZipExtractor] No storage directory found (files will not be imported)"
      end
    end

    def cleanup_temp_dir
      if @temp_dir && File.exist?(@temp_dir)
        FileUtils.rm_rf(@temp_dir)
        Rails.logger.info "[ZipExtractor] Cleaned up temporary directory: #{@temp_dir}"
      end
    end
  end
end
