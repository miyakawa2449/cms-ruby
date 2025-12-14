# frozen_string_literal: true

# My Storyセクションのタイプ管理を担当するサービス
class MyStorySectionTypeService
  def self.available_types_for(section = nil)
    new(section).available_types
  end

  def initialize(section = nil)
    @section = section
  end

  def available_types
    if @section&.persisted?
      # 編集時は現在のセクションタイプを含める
      available_types = all_types - existing_types + [@section.section_type]
    else
      # 新規作成時は既存のタイプを除外
      available_types = all_types - existing_types
    end
    
    available_types.map { |type| [section_type_label(type), type] }
  end

  private

  def all_types
    MyStorySection::SECTION_TYPES
  end

  def existing_types
    MyStorySection.pluck(:section_type)
  end

  def section_type_label(type)
    MyStorySection::SECTION_TYPE_LABELS[type]
  end
end