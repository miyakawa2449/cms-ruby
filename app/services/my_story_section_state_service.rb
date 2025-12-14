# frozen_string_literal: true

# My Storyセクションの状態管理を担当するサービス
class MyStorySectionStateService
  attr_reader :section, :errors

  def initialize(section)
    @section = section
    @errors = []
  end

  def toggle_active
    new_state = !@section.is_active?
    
    if @section.update(is_active: new_state)
      { success: true, is_active: new_state, message: status_message(new_state) }
    else
      @errors.concat(@section.errors.full_messages)
      { success: false, errors: @errors }
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << "更新に失敗しました: #{e.message}"
    { success: false, errors: @errors }
  end

  def section_details
    {
      has_background_image: @section.has_background_image?,
      has_chapter_image: @section.has_chapter_image?,
      has_gallery_images: @section.has_gallery_images?,
      additional_data_keys: @section.additional_data.keys
    }
  end

  private

  def status_message(is_active)
    status_text = is_active ? "アクティブ" : "非アクティブ"
    "セクション「#{@section.title}」を#{status_text}にしました。"
  end
end