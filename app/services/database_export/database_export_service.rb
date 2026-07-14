# frozen_string_literal: true

module DatabaseExport
  # Exports database records to JSON format
  # Includes all application models and Active Storage metadata
  class DatabaseExportService
    # Models to export in dependency order (referenced models first)
    EXPORT_MODELS = [
      AdminUser,
      Category,
      Tag,
      Section,
      Article,
      ArticleCategory,
      ArticleTag,
      SectionContent,
      Contact,
      SiteSetting
    ].freeze

    def initialize
      @export_data = {
        metadata: {},
        models: {},
        active_storage: {}
      }
    end

    # Execute the export and return the data hash
    # @return [Hash] Export data including metadata, models, and active_storage
    def call
      Rails.logger.info "[DatabaseExport] Starting database export..."

      export_metadata
      export_all_models
      export_active_storage_metadata

      Rails.logger.info "[DatabaseExport] Export completed. Total models: #{models_count.values.sum}"

      @export_data
    end

    private

    def export_metadata
      @export_data[:metadata] = {
        exported_at: Time.current.iso8601,
        rails_version: Rails.version,
        ruby_version: RUBY_VERSION,
        models_count: models_count
      }

      Rails.logger.info "[DatabaseExport] Metadata generated: #{@export_data[:metadata][:models_count]}"
    end

    def models_count
      @models_count ||= EXPORT_MODELS.each_with_object({}) do |model, hash|
        hash[model.name] = model.count
      end
    end

    def export_all_models
      EXPORT_MODELS.each do |model|
        export_model(model)
      end
    end

    def export_model(model)
      records = model.all.map { |record| serialize_record(record) }
      @export_data[:models][model.name] = records

      Rails.logger.info "[DatabaseExport] Exported #{records.size} #{model.name} records"
    end

    def serialize_record(record)
      # Export all attributes including encrypted fields
      record.attributes
    end

    def export_active_storage_metadata
      export_blobs
      export_attachments

      Rails.logger.info "[DatabaseExport] Active Storage metadata exported"
    end

    def export_blobs
      blobs = ActiveStorage::Blob.all.map(&:attributes)
      @export_data[:active_storage][:blobs] = blobs

      Rails.logger.info "[DatabaseExport] Exported #{blobs.size} Active Storage blobs"
    end

    def export_attachments
      attachments = ActiveStorage::Attachment.all.map(&:attributes)
      @export_data[:active_storage][:attachments] = attachments

      Rails.logger.info "[DatabaseExport] Exported #{attachments.size} Active Storage attachments"
    end
  end
end
