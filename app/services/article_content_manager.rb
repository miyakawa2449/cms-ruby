class ArticleContentManager
  def initialize(article)
    @article = article
  end

  # Tech stack management
  def tech_stack_list
    return [] if @article.tech_stack.blank?
    @article.tech_stack.split(',').map(&:strip).reject(&:blank?)
  end

  def tech_stack_list=(list)
    @article.tech_stack = list.join(', ') if list.is_a?(Array)
    save_article
  end

  def add_tech_stack(technology)
    current_list = tech_stack_list
    return if current_list.include?(technology)
    
    current_list << technology
    self.tech_stack_list = current_list
  end

  def remove_tech_stack(technology)
    current_list = tech_stack_list
    current_list.delete(technology)
    self.tech_stack_list = current_list
  end

  # Content processing
  def content_word_count
    return 0 if @article.content.blank?
    @article.content.gsub(/\s+/, ' ').split.length
  end

  def content_reading_time
    words_per_minute = 200 # 平均読書速度
    (content_word_count.to_f / words_per_minute).ceil
  end

  def generate_excerpt(length: 200)
    return @article.excerpt if @article.excerpt.present?
    return '' if @article.content.blank?

    # Markdownタグを除去してプレーンテキスト化
    plain_content = strip_markdown(@article.content)
    truncate_text(plain_content, length)
  end

  def update_excerpt(force: false)
    if @article.excerpt.blank? || force
      @article.excerpt = generate_excerpt
      save_article
    end
  end

  # Category and tag helpers
  def category_names
    @article.categories.pluck(:name)
  end

  def tag_names
    @article.tags.pluck(:name)
  end

  def assign_tag_names(names)
    tag_list = parse_tag_names(names)
    @article.tags = find_or_create_tags(tag_list)
    save_article
  end

  def is_work?
    @article.categories.exists?(slug: 'works')
  end

  # Work type helpers
  def work_type_display
    case @article.work_type
    when 'github'
      'GitHub プロジェクト'
    when 'external_url'
      '外部リンク'
    when 'internal'
      '内部プロジェクト'
    else
      '標準記事'
    end
  end

  private

  def save_article
    @article.save! if @article.persisted?
  end

  def strip_markdown(text)
    # 基本的なMarkdown記法を除去
    text.gsub(/#+\s*/, '')        # ヘッダー
        .gsub(/\*\*(.*?)\*\*/, '\1') # Bold
        .gsub(/\*(.*?)\*/, '\1')     # Italic
        .gsub(/`(.*?)`/, '\1')       # Code
        .gsub(/\[(.*?)\]\(.*?\)/, '\1') # Links
        .gsub(/!\[.*?\]\(.*?\)/, '')    # Images
        .gsub(/>\s*/, '')               # Blockquotes
        .gsub(/^\s*[-*+]\s+/, '')       # List items
        .gsub(/\n+/, ' ')               # Multiple newlines to space
        .strip
  end

  def truncate_text(text, length)
    return text if text.length <= length
    
    truncated = text[0...length]
    last_space = truncated.rindex(' ')
    
    if last_space && last_space > length * 0.8
      truncated = truncated[0...last_space]
    end
    
    truncated + '...'
  end

  def parse_tag_names(names)
    case names
    when String
      names.split(',').map(&:strip).reject(&:blank?)
    when Array
      names.map(&:to_s).map(&:strip).reject(&:blank?)
    else
      []
    end
  end

  def find_or_create_tags(tag_names)
    tag_names.filter_map do |name|
      # 大文字小文字を無視して既存タグを検索
      existing_tag = Tag.find_by('LOWER(name) = ?', name.downcase)
      next existing_tag if existing_tag

      # 新規タグ作成（エラー時はログ出力してスキップ）
      new_tag = Tag.create(name: name)
      if new_tag.persisted?
        new_tag
      else
        Rails.logger.warn("Tag creation failed for '#{name}': #{new_tag.errors.full_messages.join(', ')}")
        nil
      end
    end
  end
end