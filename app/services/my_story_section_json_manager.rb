class MyStorySectionJsonManager
  def initialize(section)
    @section = section
  end

  # Timeline関連
  def timeline_years
    years = additional_data['years']
    normalize_to_array(years)
  end

  def timeline_years=(years)
    additional_data['years'] = years
    save_section
  end

  # Chapter関連
  def chapter_skills
    skills = additional_data['skills']
    normalize_to_array(skills)
  end

  def chapter_skills=(skills)
    additional_data['skills'] = skills
    save_section
  end

  def chapter_achievements
    achievements = additional_data['achievements']
    normalize_to_array(achievements)
  end

  def chapter_achievements=(achievements)
    additional_data['achievements'] = achievements
    save_section
  end

  def chapter_quote
    additional_data['quote']
  end

  def chapter_quote=(quote)
    additional_data['quote'] = quote
    save_section
  end

  # Project関連
  def project_items
    items = additional_data.dig('projects', 'items')
    normalize_to_array(items)
  end

  def project_items=(items)
    additional_data['projects'] ||= {}
    additional_data['projects']['items'] = items
    save_section
  end

  # CTA関連
  def cta_buttons
    buttons = additional_data.dig('cta', 'buttons')
    normalize_to_array(buttons)
  end

  def cta_buttons=(buttons)
    additional_data['cta'] ||= {}
    additional_data['cta']['buttons'] = buttons
    save_section
  end

  # Skills関連
  def skills_list
    skills = additional_data.dig('skills', 'list')
    normalize_to_array(skills)
  end

  def skills_list=(skills)
    additional_data['skills'] ||= {}
    additional_data['skills']['list'] = skills
    save_section
  end

  # JSON構造の一括取得
  def all_data
    additional_data
  end

  # JSON構造の一括設定
  def update_data(data)
    @section.additional_data = data
    save_section
  end

  # 特定キーの存在確認
  def has_data?(key)
    additional_data.key?(key)
  end

  # 特定キーの削除
  def remove_data(key)
    additional_data.delete(key)
    save_section
  end

  private

  def additional_data
    @section.additional_data ||= {}
  end

  def save_section
    @section.save! if @section.persisted?
  end

  def normalize_to_array(value)
    case value
    when Array
      value
    when String
      value.present? ? [value] : []
    else
      []
    end
  end
end