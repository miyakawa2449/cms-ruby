# frozen_string_literal: true

require "zip"

module DatabaseExport
  # Generates a ZIP file containing data.json and storage files
  class ZipGeneratorService
    def initialize(temp_dir, export_data)
      @temp_dir = temp_dir
      @export_data = export_data
      @timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    end

    # Execute the ZIP generation
    # @return [String] Path to the generated ZIP file
    def call
      Rails.logger.info "[ZipGenerator] Starting ZIP generation..."

      write_data_json
      zip_path = create_zip_file

      Rails.logger.info "[ZipGenerator] ZIP file created: #{zip_path}"

      zip_path
    rescue StandardError => e
      Rails.logger.error "[ZipGenerator] ZIP generation failed: #{e.message}"
      Rails.logger.error e.backtrace.first(10).join("\n")
      raise
    end

    private

    def write_data_json
      data_json_path = File.join(@temp_dir, "data.json")
      File.write(data_json_path, JSON.pretty_generate(@export_data))

      Rails.logger.info "[ZipGenerator] data.json written (#{File.size(data_json_path)} bytes)"
    end

    def create_zip_file
      zip_path = generate_zip_path

      Zip::File.open(zip_path, Zip::File::CREATE) do |zipfile|
        add_directory_to_zip(zipfile, @temp_dir, "")
      end

      log_zip_summary(zip_path)
      zip_path
    end

    def generate_zip_path
      File.join(Dir.tmpdir, "database_export_#{@timestamp}.zip")
    end

    def add_directory_to_zip(zipfile, source_dir, prefix)
      Dir.glob("#{source_dir}/**/*").each do |file|
        # Calculate relative path from source_dir
        relative_path = file.sub("#{source_dir}/", "")
        zip_entry_name = prefix.empty? ? relative_path : File.join(prefix, relative_path)

        if File.directory?(file)
          # Add empty directories
          zipfile.mkdir(zip_entry_name) unless zipfile.find_entry(zip_entry_name)
        else
          # Add files
          zipfile.add(zip_entry_name, file)
        end
      end
    end

    def log_zip_summary(zip_path)
      zip_size = File.size(zip_path)
      entry_count = 0

      Zip::File.open(zip_path) do |zipfile|
        entry_count = zipfile.entries.count
      end

      Rails.logger.info "[ZipGenerator] ZIP contains #{entry_count} entries (#{format_size(zip_size)})"
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
