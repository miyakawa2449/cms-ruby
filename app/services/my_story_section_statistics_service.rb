# frozen_string_literal: true

# My Storyセクションの統計情報を管理するサービス
class MyStorySectionStatisticsService
  attr_reader :sections

  def initialize(sections)
    @sections = sections
  end

  def calculate_stats
    {
      total_sections: total_count,
      active_sections: active_count,
      inactive_sections: inactive_count,
      section_type_distribution: section_type_distribution,
      image_usage_stats: image_usage_stats
    }
  end

  def section_index_stats
    {
      total_sections: total_count,
      active_sections: active_count,
      inactive_sections: inactive_count
    }
  end

  private

  def total_count
    @total_count ||= @sections.count
  end

  def active_count
    @active_count ||= @sections.select(&:is_active).count
  end

  def inactive_count
    total_count - active_count
  end

  def section_type_distribution
    @sections.group_by(&:section_type).transform_values(&:count)
  end

  def image_usage_stats
    {
      with_background_image: @sections.select(&:has_background_image?).count,
      with_chapter_image: @sections.select(&:has_chapter_image?).count,
      with_gallery_images: @sections.select(&:has_gallery_images?).count
    }
  end
end