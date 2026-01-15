module SectionHelper
  # セクション取得のヘルパーメソッド

  # Aboutセクションの情報を取得
  def about_section
    @about_section ||= Section.find_by(name: "about")
  end

  # Heroセクションの情報を取得
  def hero_section
    @hero_section ||= Section.find_by(name: "hero")
  end

  # 指定されたセクションを取得
  def find_section(name)
    Section.find_by(name: name)
  end

  # アクティブなセクションのみ取得
  def active_sections
    @active_sections ||= Section.visible.ordered
  end

  # セクションのアクティブコンテンツを取得
  def section_active_content(section)
    return {} unless section&.active_content

    begin
      section.active_content_data || {}
    rescue => e
      Rails.logger.error "Error loading content for section #{section.name}: #{e.message}"
      {}
    end
  end

  # セクションが個別フィールドを使用するかチェック
  def individual_field_section?(section_name)
    %w[hero about my-story works].include?(section_name)
  end

  # セクションの表示可否判定
  def section_displayable?(section, content_data = {})
    return true if individual_field_section?(section.name)
    return false unless section.active_content
    content_data.present?
  end
end
