# frozen_string_literal: true

namespace :media_metadata do
  desc "Create MediaMetadata records for existing Active Storage blobs"
  task sync: :environment do
    puts "Syncing MediaMetadata records..."

    created_count = 0
    skipped_count = 0

    ActiveStorage::Blob.find_each do |blob|
      # Skip non-image files
      unless blob.content_type&.start_with?('image/')
        skipped_count += 1
        next
      end

      # Check if MediaMetadata already exists
      if MediaMetadata.exists?(blob: blob)
        skipped_count += 1
        next
      end

      # Analyze blob if not analyzed
      blob.analyze unless blob.analyzed?

      # Create MediaMetadata
      MediaMetadata.create!(
        blob: blob,
        mime_type: blob.content_type,
        file_size: blob.byte_size,
        width: blob.metadata[:width],
        height: blob.metadata[:height]
      )

      created_count += 1
      print "."
    rescue => e
      puts "\nError creating MediaMetadata for blob #{blob.id}: #{e.message}"
    end

    puts "\n\nSync completed!"
    puts "Created: #{created_count}"
    puts "Skipped: #{skipped_count}"
  end

  desc "Clean up MediaMetadata records for deleted blobs"
  task cleanup: :environment do
    puts "Cleaning up MediaMetadata records..."

    deleted_count = 0

    MediaMetadata.find_each do |metadata|
      unless ActiveStorage::Blob.exists?(metadata.blob_id)
        metadata.destroy
        deleted_count += 1
        print "."
      end
    end

    puts "\n\nCleanup completed!"
    puts "Deleted: #{deleted_count}"
  end

  desc "Update usage count for all MediaMetadata records"
  task update_usage: :environment do
    puts "Updating usage count for MediaMetadata records..."

    updated_count = 0

    MediaMetadata.find_each do |metadata|
      # Find all articles using this blob
      usage_count = 0

      # Check thumbnail_image
      usage_count += Article.joins(:thumbnail_image_attachment)
                            .where(active_storage_attachments: { blob_id: metadata.blob_id })
                            .count

      # Check content_images
      usage_count += ActiveStorage::Attachment
                      .where(name: 'content_images', blob_id: metadata.blob_id)
                      .count

      # Update usage_count
      if metadata.usage_count != usage_count
        metadata.update_column(:usage_count, usage_count)
        updated_count += 1
        print "."
      end
    end

    puts "\n\nUpdate completed!"
    puts "Updated: #{updated_count}"
  end
end
