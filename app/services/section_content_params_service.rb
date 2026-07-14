# frozen_string_literal: true

# セクションコンテンツのパラメータ処理を担当するサービス
class SectionContentParamsService
  def self.process(params)
    new(params).process
  end

  def initialize(params)
    @params = params
  end

  def process
    # 基本フィールドと画像を許可
    permitted_params = @params.require(:section_content).permit(
      :is_active, :hero_image, :profile_image, :background_image,
      :main_message, :sub_message, :career_description,
      :cta_primary_text, :cta_primary_url, :cta_secondary_text, :cta_secondary_url,
      :profile_text, :frontend_skills, :backend_skills, :core_skills, :experience_text,
      :badge_text, :main_title, :sub_title,
      :phase1_year, :phase1_title, :phase1_description, :phase1_period,
      :phase2_year, :phase2_title, :phase2_description, :phase2_period,
      :phase3_year, :phase3_title, :phase3_description, :phase3_period
    )

    # contentパラメータを処理
    content_data = process_content_params

    permitted_params.merge(content: content_data)
  end

  private

  def process_content_params
    return {} unless @params[:section_content][:content].present?

    if @params[:section_content][:content].is_a?(String)
      parse_json_string(@params[:section_content][:content])
    elsif @params[:section_content][:content].is_a?(ActionController::Parameters)
      process_structured_params(@params[:section_content][:content])
    else
      {}
    end
  end

  def parse_json_string(content_string)
    JSON.parse(content_string)
  rescue JSON::ParserError
    {}
  end

  def process_structured_params(content_params)
    content_data = {}

    # 基本フィールドを許可
    basic_fields = [ :title, :subtitle, :description, :image_url, :cta_text, :cta_url, :email, :story, :posts_count ]
    basic_fields.each do |field|
      content_data[field] = content_params[field] if content_params[field].present?
    end

    # JSONフィールドの処理
    json_fields = [ :skills, :services, :works, :social_links ]
    json_fields.each do |field|
      if content_params[field].present?
        content_data[field] = parse_json_field(content_params[field])
      end
    end

    content_data
  end

  def parse_json_field(field_value)
    JSON.parse(field_value)
  rescue JSON::ParserError
    []
  end
end
