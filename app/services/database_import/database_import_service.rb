# frozen_string_literal: true

module DatabaseImport
  # Imports database records from data.json
  # Handles transaction management, foreign key constraints, and password reset
  class DatabaseImportService
    class ImportError < StandardError; end

    # Default password for imported AdminUsers (prefer ENV, fallback in dev/test)
    DEFAULT_PASSWORD = "test_password_123!"

    # Models to import in dependency order (referenced models first)
    IMPORT_ORDER = %w[
      AdminUser
      Category
      Tag
      Section
      Article
      ArticleCategory
      ArticleTag
      SectionContent
      Contact
      SiteSetting
    ].freeze

    def initialize(data_json_path)
      @data_json_path = data_json_path
      @data = nil
      @imported_counts = {}
    end

    # Execute the import within a transaction
    # @return [Hash] Import results with counts
    def call
      Rails.logger.info "[DatabaseImport] Starting database import..."

      load_data
      validate_data_structure

      ActiveRecord::Base.transaction do
        clear_existing_data
        import_all_models
        import_active_storage_metadata
        reset_admin_passwords
        update_counter_caches
      end

      # insertベースのリストアはモデルのコールバック（キャッシュ無効化）を
      # 経由しないため、旧データのキャッシュを明示的に全消去する（監査M-2）
      Rails.cache.clear

      log_import_summary

      { success: true, imported: @imported_counts }
    rescue StandardError => e
      Rails.logger.error "[DatabaseImport] Import failed: #{e.message}"
      Rails.logger.error e.backtrace.first(20).join("\n")
      raise ImportError, "インポートに失敗しました: #{e.message}"
    end

    private

    def load_data
      @data = JSON.parse(File.read(@data_json_path))
      Rails.logger.info "[DatabaseImport] Data loaded from: #{@data_json_path}"
    end

    def validate_data_structure
      unless @data.is_a?(Hash) && @data["metadata"] && @data["models"]
        raise ImportError, "data.jsonの構造が不正です"
      end

      Rails.logger.info "[DatabaseImport] Data structure validated"
      Rails.logger.info "[DatabaseImport] Export metadata: #{@data['metadata']}"
    end

    def clear_existing_data
      Rails.logger.info "[DatabaseImport] Clearing existing data..."

      # Clear in reverse order to handle foreign key constraints
      clear_active_storage
      IMPORT_ORDER.reverse.each do |model_name|
        model_class = model_name.constantize
        count = model_class.count
        model_class.delete_all
        Rails.logger.info "[DatabaseImport] Cleared #{count} #{model_name} records"
      end
    end

    def clear_active_storage
      ActiveStorage::Attachment.delete_all
      ActiveStorage::Blob.delete_all
      Rails.logger.info "[DatabaseImport] Cleared Active Storage records"
    end

    def import_all_models
      Rails.logger.info "[DatabaseImport] Importing model records..."

      IMPORT_ORDER.each do |model_name|
        import_model(model_name)
      end
    end

    def import_model(model_name)
      records = @data["models"][model_name] || []
      return if records.empty?

      model_class = model_name.constantize
      imported = 0

      records.each do |record_data|
        import_single_record(model_class, record_data)
        imported += 1
      end

      @imported_counts[model_name] = imported
      Rails.logger.info "[DatabaseImport] Imported #{imported} #{model_name} records"
    end

    def import_single_record(model_class, record_data)
      # Create record with all attributes including id
      record = model_class.new

      record_data.each do |key, value|
        # Skip attributes that don't exist on the model
        next unless record.respond_to?("#{key}=")

        record.send("#{key}=", value)
      end

      # Use insert to preserve original IDs
      model_class.insert(record.attributes.compact)
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.warn "[DatabaseImport] Duplicate record skipped: #{model_class.name} - #{e.message}"
    end

    def import_active_storage_metadata
      Rails.logger.info "[DatabaseImport] Importing Active Storage metadata..."

      import_blobs
      import_attachments
    end

    def import_blobs
      blobs = @data.dig("active_storage", "blobs") || []
      return if blobs.empty?

      blobs.each do |blob_data|
        ActiveStorage::Blob.insert(blob_data.compact)
      end

      @imported_counts["ActiveStorage::Blob"] = blobs.size
      Rails.logger.info "[DatabaseImport] Imported #{blobs.size} blobs"
    end

    def import_attachments
      attachments = @data.dig("active_storage", "attachments") || []
      return if attachments.empty?

      attachments.each do |attachment_data|
        ActiveStorage::Attachment.insert(attachment_data.compact)
      end

      @imported_counts["ActiveStorage::Attachment"] = attachments.size
      Rails.logger.info "[DatabaseImport] Imported #{attachments.size} attachments"
    end

    def reset_admin_passwords
      Rails.logger.info "[DatabaseImport] Resetting AdminUser passwords..."

      reset_password = self.class.admin_reset_password
      if reset_password.blank?
        Rails.logger.warn "[DatabaseImport] ADMIN_RESET_PASSWORD is not set. Skipping admin password reset."
        return
      end

      AdminUser.find_each do |admin|
        admin.update_columns(
          encrypted_password: AdminUser.new(password: reset_password).encrypted_password
        )
      end

      # 開発環境用のデフォルトユーザーを確保
      if Rails.env.development? || Rails.env.test?
        ensure_default_admin_user(reset_password)
      end

      Rails.logger.info "[DatabaseImport] Reset passwords for #{AdminUser.count} admin users"
      Rails.logger.warn "[DatabaseImport] All admin passwords have been reset. Set ADMIN_RESET_PASSWORD to change."
    end

    def ensure_default_admin_user(reset_password)
      default_email = ENV.fetch("ADMIN_EMAIL", "admin@example.test")

      unless AdminUser.exists?(email: default_email)
        AdminUser.create!(
          email: default_email,
          password: reset_password,
          password_confirmation: reset_password
        )
        Rails.logger.info "[DatabaseImport] Created default admin user: #{default_email}"
      else
        Rails.logger.info "[DatabaseImport] Default admin user already exists: #{default_email}"
      end
    end

    def self.admin_reset_password
      ENV["ADMIN_RESET_PASSWORD"].presence ||
        ENV["ADMIN_PASSWORD"].presence ||
        (Rails.env.production? ? nil : DEFAULT_PASSWORD)
    end

    def update_counter_caches
      Rails.logger.info "[DatabaseImport] Updating counter caches..."

      update_category_article_counts
      update_tag_article_counts

      Rails.logger.info "[DatabaseImport] Counter caches updated"
    end

    def update_category_article_counts
      Category.find_each do |category|
        category.update_column(:article_count, category.articles.count)
      end
    end

    def update_tag_article_counts
      # Check if Tag model has article_count column
      return unless Tag.column_names.include?("article_count")

      Tag.find_each do |tag|
        tag.update_column(:article_count, tag.articles.count)
      end
    end

    def log_import_summary
      total = @imported_counts.values.sum
      Rails.logger.info "[DatabaseImport] Import completed successfully"
      Rails.logger.info "[DatabaseImport] Total records imported: #{total}"
      Rails.logger.info "[DatabaseImport] Details: #{@imported_counts}"
    end
  end
end
