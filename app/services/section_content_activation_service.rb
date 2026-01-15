# frozen_string_literal: true

# セクションコンテンツのアクティベーション管理を担当するサービス
class SectionContentActivationService
  attr_reader :section_content, :errors

  def initialize(section_content)
    @section_content = section_content
    @errors = []
  end

  def activate!
    @section_content.activate!
    { success: true, message: "コンテンツを公開しました。" }
  rescue StandardError => e
    @errors << "公開に失敗しました: #{e.message}"
    { success: false, errors: @errors }
  end

  def deactivate!
    @section_content.update!(is_active: false)
    { success: true, message: "コンテンツを非公開にしました。" }
  rescue StandardError => e
    @errors << "非公開に失敗しました: #{e.message}"
    { success: false, errors: @errors }
  end

  def toggle_active
    new_state = !@section_content.is_active?

    if @section_content.update(is_active: new_state)
      status = new_state ? "公開" : "非公開"
      { success: true, is_active: new_state, message: "コンテンツを#{status}にしました。" }
    else
      @errors.concat(@section_content.errors.full_messages)
      { success: false, errors: @errors }
    end
  end
end
