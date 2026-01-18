# frozen_string_literal: true

class Admin::DatabaseController < Admin::BaseController
  # GET /admin/database/export
  # Exports database and Active Storage files as a ZIP download
  def export
    Rails.logger.info "[DatabaseExport] Export started by #{current_admin_user.email}"

    temp_dir = Dir.mktmpdir("database_export")

    begin
      # Step 1: Export database records to JSON
      export_data = DatabaseExport::DatabaseExportService.new.call

      # Step 2: Copy Active Storage files
      DatabaseExport::ActiveStorageExportService.new(temp_dir).call

      # Step 3: Generate ZIP file
      zip_path = DatabaseExport::ZipGeneratorService.new(temp_dir, export_data).call

      # Step 4: Send ZIP file as download
      send_zip_file(zip_path)

      Rails.logger.info "[DatabaseExport] Export completed successfully"
    rescue StandardError => e
      handle_export_error(e)
    ensure
      # Clean up temporary directory
      FileUtils.rm_rf(temp_dir) if temp_dir && File.exist?(temp_dir)
    end
  end

  # GET /admin/database/import_form
  # Displays the import form with file upload
  def import_form
    Rails.logger.info "[DatabaseImport] Import form accessed by #{current_admin_user.email}"

    @is_production = Rails.env.production?
    @model_counts = calculate_model_counts
  end

  # POST /admin/database/import
  # Processes the uploaded ZIP file and imports data
  def import
    Rails.logger.info "[DatabaseImport] Import started by #{current_admin_user.email}"

    unless params[:zip_file].present?
      redirect_to import_form_admin_database_path, alert: "ZIPファイルを選択してください"
      return
    end

    zip_extractor = nil

    begin
      # Step 1: Save uploaded file temporarily
      uploaded_file = params[:zip_file]
      temp_zip_path = save_uploaded_file(uploaded_file)

      # Step 2: Extract and validate ZIP
      zip_extractor = DatabaseImport::ZipExtractorService.new(temp_zip_path)
      extracted_dir = zip_extractor.call

      # Step 3: Import database records
      data_json_path = File.join(extracted_dir, "data.json")
      result = DatabaseImport::DatabaseImportService.new(data_json_path).call

      # Step 4: Import Active Storage files
      storage_path = File.join(extracted_dir, "storage")
      DatabaseImport::ActiveStorageImportService.new(storage_path).call

      Rails.logger.info "[DatabaseImport] Import completed successfully"

      redirect_to admin_dashboard_path,
        notice: "インポートが完了しました。#{format_import_result(result)}"
    rescue DatabaseImport::ZipExtractorService::InvalidZipError,
           DatabaseImport::ZipExtractorService::MissingDataJsonError => e
      handle_import_validation_error(e)
    rescue DatabaseImport::DatabaseImportService::ImportError => e
      handle_import_error(e)
    rescue StandardError => e
      handle_import_error(e)
    ensure
      # Clean up
      zip_extractor&.cleanup
      FileUtils.rm_f(temp_zip_path) if defined?(temp_zip_path) && temp_zip_path
    end
  end

  private

  # Export helpers

  def send_zip_file(zip_path)
    zip_filename = File.basename(zip_path)
    zip_data = File.binread(zip_path)

    send_data(
      zip_data,
      filename: zip_filename,
      type: "application/zip",
      disposition: "attachment"
    )

    # Clean up the ZIP file after reading
    FileUtils.rm_f(zip_path)
  end

  def handle_export_error(error)
    Rails.logger.error "[DatabaseExport] Export failed: #{error.message}"
    Rails.logger.error error.backtrace.first(20).join("\n")

    redirect_to admin_dashboard_path, alert: "エクスポートに失敗しました: #{error.message}"
  end

  # Import helpers

  def save_uploaded_file(uploaded_file)
    temp_path = File.join(Dir.tmpdir, "upload_#{Time.current.to_i}_#{uploaded_file.original_filename}")
    File.binwrite(temp_path, uploaded_file.read)
    temp_path
  end

  def calculate_model_counts
    {
      admin_users: AdminUser.count,
      articles: Article.count,
      categories: Category.count,
      tags: Tag.count,
      sections: Section.count,
      contacts: Contact.count
    }
  end

  def format_import_result(result)
    total = result[:imported].values.sum
    "#{total}件のレコードをインポートしました。"
  end

  def handle_import_validation_error(error)
    Rails.logger.warn "[DatabaseImport] Validation error: #{error.message}"

    redirect_to import_form_admin_database_path, alert: error.message
  end

  def handle_import_error(error)
    Rails.logger.error "[DatabaseImport] Import failed: #{error.message}"
    Rails.logger.error error.backtrace.first(20).join("\n")

    redirect_to import_form_admin_database_path,
      alert: "インポートに失敗しました: #{error.message}"
  end
end
