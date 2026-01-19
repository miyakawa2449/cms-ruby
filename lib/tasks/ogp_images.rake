# frozen_string_literal: true

require "stringio"

namespace :ogp do
  desc "Generate ogp_image for articles that have thumbnail_image but no ogp_image"
  task generate_images: :environment do
    processed = 0
    skipped = 0
    failed = 0

    Article.includes(thumbnail_image_attachment: :blob, ogp_image_attachment: :blob).find_each do |article|
      if !article.thumbnail_image.attached?
        skipped += 1
        next
      end

      if article.ogp_image.attached?
        skipped += 1
        next
      end

      begin
        variant = article.thumbnail_image.variant(
          resize_to_fill: [1200, 630],
          format: :jpg
        ).processed
        article.ogp_image.attach(
          io: StringIO.new(variant.download),
          filename: "ogp_#{article.id}.jpg",
          content_type: "image/jpeg"
        )
        processed += 1
        puts "OK: Article ##{article.id}"
      rescue => e
        failed += 1
        warn "FAIL: Article ##{article.id} - #{e.class}: #{e.message}"
      end
    end

    puts "Done. processed=#{processed} skipped=#{skipped} failed=#{failed}"
  end
end
