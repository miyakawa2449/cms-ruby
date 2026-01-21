class MyStorySectionValidator
  def initialize(section)
    @section = section
    @errors = {}
  end

  def validate_all
    validate_section_type
    validate_content_structure
    validate_required_fields
    validate_json_data
    validate_position_constraints

    @errors.empty?
  end

  def errors
    @errors
  end

  def error_messages
    @errors.values.flatten
  end

  # セクションタイプ固有のバリデーション
  def validate_section_type
    case @section.section_type
    when "hero"
      validate_hero_section
    when "timeline"
      validate_timeline_section
    when "chapter_1", "chapter_2", "chapter_3"
      validate_chapter_section
    when "skills_integration"
      validate_skills_section
    when "projects"
      validate_projects_section
    when "cta"
      validate_cta_section
    else
      add_error(:section_type, "Unknown section type: #{@section.section_type}")
    end
  end

  def validate_content_structure
    # 基本構造のチェック
    if @section.title.blank?
      add_error(:title, "Title cannot be blank")
    elsif @section.title.length > 255
      add_error(:title, "Title is too long (maximum 255 characters)")
    end

    if @section.subtitle.present? && @section.subtitle.length > 255
      add_error(:subtitle, "Subtitle is too long (maximum 255 characters)")
    end
  end

  def validate_required_fields
    required_fields = required_fields_for_section_type

    required_fields.each do |field|
      if field_missing?(field)
        add_error(field, "#{field.to_s.humanize} is required for #{@section.section_type} section")
      end
    end
  end

  def validate_json_data
    return unless @section.additional_data.present?

    begin
      # JSONBデータの構造チェック
      validate_json_structure(@section.additional_data)
    rescue StandardError => e
      add_error(:additional_data, "Invalid JSON structure: #{e.message}")
    end
  end

  def validate_position_constraints
    if @section.position.nil?
      add_error(:position, "Position cannot be nil")
    elsif @section.position < 0
      add_error(:position, "Position cannot be negative")
    end

    # 同じposition値の重複チェック（自分以外）
    duplicate = MyStorySection.where(position: @section.position)
                              .where.not(id: @section.id)
                              .first
    if duplicate
      add_error(:position, "Position #{@section.position} is already taken by another section")
    end
  end

  private

  def validate_hero_section
    # ヒーローセクションは通常背景画像が必要
    unless @section.has_background_image?
      add_warning(:background_image, "Hero section should have a background image")
    end
  end

  def validate_timeline_section
    json_manager = MyStorySectionJsonManager.new(@section)
    years = json_manager.timeline_years

    if years.empty?
      add_error(:timeline_years, "Timeline section must have years data")
    end

    # 年データの形式チェック
    years.each do |year_data|
      unless year_data.is_a?(Hash) && year_data.key?("year")
        add_error(:timeline_years, "Invalid year data structure")
      end
    end
  end

  def validate_chapter_section
    json_manager = MyStorySectionJsonManager.new(@section)

    # チャプターには通常スキルや実績データが必要
    if json_manager.chapter_skills.empty?
      add_warning(:chapter_skills, "Chapter section should have skills data")
    end

    if @section.content.blank?
      add_error(:content, "Chapter section must have content")
    end
  end

  def validate_skills_section
    json_manager = MyStorySectionJsonManager.new(@section)

    if json_manager.skills_list.empty?
      add_error(:skills_list, "Skills section must have skills list")
    end
  end

  def validate_projects_section
    json_manager = MyStorySectionJsonManager.new(@section)

    if json_manager.project_items.empty?
      add_warning(:project_items, "Projects section should have project items")
    end
  end

  def validate_cta_section
    json_manager = MyStorySectionJsonManager.new(@section)

    if json_manager.cta_buttons.empty?
      add_error(:cta_buttons, "CTA section must have buttons")
    end
  end

  def required_fields_for_section_type
    case @section.section_type
    when "hero"
      [ :title ]
    when "timeline"
      [ :title ]
    when "chapter_1", "chapter_2", "chapter_3"
      [ :title, :content ]
    when "skills_integration"
      [ :title ]
    when "projects"
      [ :title ]
    when "cta"
      [ :title ]
    else
      [ :title ]
    end
  end

  def field_missing?(field)
    case field
    when :content
      @section.content.blank?
    when :title
      @section.title.blank?
    when :subtitle
      @section.subtitle.blank?
    else
      false
    end
  end

  def validate_json_structure(data)
    # 深いネスト構造の制限
    max_depth = 5
    check_depth(data, max_depth)

    # 配列サイズの制限
    check_array_sizes(data)
  end

  def check_depth(obj, remaining_depth)
    return if remaining_depth <= 0
    raise "JSON structure too deep" if remaining_depth == 0

    case obj
    when Hash
      obj.each_value { |v| check_depth(v, remaining_depth - 1) }
    when Array
      obj.each { |item| check_depth(item, remaining_depth - 1) }
    end
  end

  def check_array_sizes(obj, max_size = 100)
    case obj
    when Hash
      obj.each_value { |v| check_array_sizes(v, max_size) }
    when Array
      raise "Array too large (#{obj.size} > #{max_size})" if obj.size > max_size
      obj.each { |item| check_array_sizes(item, max_size) }
    end
  end

  def add_error(field, message)
    @errors[field] ||= []
    @errors[field] << message
  end

  def add_warning(field, message)
    Rails.logger.warn "MyStorySection validation warning [#{field}]: #{message}"
  end
end
