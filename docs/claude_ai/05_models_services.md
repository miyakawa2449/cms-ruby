# モデル＆サービス層仕様書

## モデル層概要

### モデル構成
- **総モデル数**: 15個
- **Concerns使用**: 3個（Publishable, Positionable, JsonStorable）
- **Service委譲パターン**: Article, SectionContent, MyStorySection

## 主要モデル仕様

### 1. AdminUser（管理者）

```ruby
class AdminUser < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :confirmable, :lockable, :timeoutable, :trackable

  # Associations
  has_many :articles, dependent: :restrict_with_error
  has_many :published_section_contents, 
           class_name: 'SectionContent', 
           foreign_key: 'published_by'

  # Validations
  validates :email, presence: true, uniqueness: true
  validates :password, length: { minimum: 8 }, if: :password_required?

  # Scopes
  scope :active, -> { where(locked_at: nil) }
  scope :admins, -> { where(role: 'admin') }
end
```

### 2. Article（記事・Works兼用）

```ruby
class Article < ApplicationRecord
  include Publishable
  
  # Associations
  belongs_to :admin_user
  has_many :article_categories, dependent: :destroy
  has_many :categories, through: :article_categories
  has_many :article_tags, dependent: :destroy
  has_many :tags, through: :article_tags
  has_one_attached :thumbnail_image

  # Enums
  enum :work_type, {
    standard: nil,
    github: 'github',
    external_url: 'external_url', 
    internal: 'internal'
  }, suffix: true

  # Validations
  validates :title, presence: true, length: { maximum: 255 }
  validates :slug, presence: true, uniqueness: { case_sensitive: false }
  validates :content, presence: true
  validates :status, inclusion: { in: %w[draft published scheduled archived] }

  # Scopes
  scope :published, -> { where(status: 'published', published_at: ..Time.current) }
  scope :draft, -> { where(status: 'draft') }
  scope :recent, -> { order(published_at: :desc) }
  scope :works, -> { joins(:categories).where(categories: { slug: 'works' }) }
  scope :standard_blog, -> { joins(:categories).where.not(categories: { slug: 'works' }) }

  # Service delegation
  delegate :tech_stack_list, :tech_stack_list=,
           :category_names, :tag_names,
           :is_work?, :content_word_count, :content_reading_time,
           to: :content_manager

  delegate :to_param, :url_path, :canonical_url,
           :seo_title, :seo_description, :seo_keywords,
           :og_title, :og_description, :structured_data,
           to: :meta_manager

  delegate :published?, :draft?, :scheduled?, :archived?,
           :publishable?, :status_display,
           to: :publishing_manager

  # Service instances
  def content_manager
    @content_manager ||= ArticleContentManager.new(self)
  end

  def meta_manager
    @meta_manager ||= ArticleMetaManager.new(self)
  end

  def publishing_manager
    @publishing_manager ||= ArticlePublishingManager.new(self)
  end
end
```

### 3. Category（カテゴリ）

```ruby
class Category < ApplicationRecord
  include Positionable

  # Self-referential association
  belongs_to :parent, class_name: 'Category', optional: true
  has_many :children, class_name: 'Category', 
           foreign_key: 'parent_id', 
           dependent: :destroy

  # Article associations
  has_many :article_categories, dependent: :destroy
  has_many :articles, through: :article_categories

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: { scope: :parent_id }
  validate :prevent_circular_reference
  validate :max_depth_validation

  # Scopes
  scope :root_categories, -> { where(parent_id: nil) }
  scope :with_articles, -> { joins(:articles).distinct }

  # Callbacks
  before_validation :generate_slug
  after_save :update_article_count
  after_destroy :update_article_count

  # Instance methods
  def full_path
    parent ? "#{parent.slug}/#{slug}" : slug
  end

  def ancestors
    node, nodes = self, []
    nodes << node = node.parent while node.parent
    nodes.reverse
  end

  def depth
    ancestors.size
  end
end
```

### 4. Section（セクション）

```ruby
class Section < ApplicationRecord
  include Positionable
  include Publishable

  # Constants
  SECTION_NAMES = %w[
    hero about service my_story works blog contact footer
  ].freeze

  # Associations
  has_many :section_contents, dependent: :destroy
  has_one :active_content, 
          -> { where(is_active: true) }, 
          class_name: 'SectionContent'

  # Validations
  validates :name, presence: true, 
            uniqueness: true, 
            inclusion: { in: SECTION_NAMES }
  validates :display_name, presence: true

  # Scopes
  scope :visible, -> { where(is_visible: true) }
  scope :for_portfolio, -> { visible.ordered }

  # Class methods
  def self.seed_defaults
    SECTION_NAMES.each_with_index do |name, index|
      find_or_create_by(name: name) do |section|
        section.display_name = name.humanize.titleize
        section.position = index + 1
      end
    end
  end

  # Instance methods
  def current_content
    active_content || section_contents.build
  end

  def activate_version!(version_id)
    SectionContentActivationService.new(self, version_id).activate!
  end
end
```

### 5. SectionContent（セクションコンテンツ）

```ruby
class SectionContent < ApplicationRecord
  # Associations
  belongs_to :section
  belongs_to :publisher, 
             class_name: 'AdminUser', 
             foreign_key: 'published_by',
             optional: true

  # Active Storage
  has_one_attached :hero_image
  has_one_attached :profile_image
  has_one_attached :background_image

  # Validations
  validates :version, presence: true, 
            uniqueness: { scope: :section_id }
  validates :content, presence: true

  # Scopes
  scope :active, -> { where(is_active: true) }
  scope :published, -> { where.not(published_at: nil) }
  scope :versions_for, ->(section) { where(section: section).order(version: :desc) }

  # Callbacks
  before_validation :set_next_version, on: :create
  after_save :deactivate_other_versions, if: :is_active?

  # JSONB content management
  store_accessor :content, :hero_title, :hero_subtitle, :hero_cta_text

  # Instance methods
  def activate!
    update!(is_active: true, published_at: Time.current)
  end

  def duplicate
    dup.tap do |new_content|
      new_content.version = nil
      new_content.is_active = false
      new_content.published_at = nil
      new_content.published_by = nil
    end
  end

  private

  def set_next_version
    self.version = section.section_contents.maximum(:version).to_i + 1
  end

  def deactivate_other_versions
    section.section_contents
           .where.not(id: id)
           .update_all(is_active: false)
  end
end
```

## Concerns（共通機能モジュール）

### 1. Publishable（公開管理）

```ruby
module Publishable
  extend ActiveSupport::Concern

  included do
    scope :published, -> { where(status: 'published') }
    scope :draft, -> { where(status: 'draft') }
    scope :scheduled, -> { where(status: 'scheduled') }
    scope :archived, -> { where(status: 'archived') }

    validates :status, inclusion: { 
      in: %w[draft published scheduled archived] 
    }
  end

  def published?
    status == 'published' && published_at.present? && published_at <= Time.current
  end

  def draft?
    status == 'draft'
  end

  def scheduled?
    status == 'scheduled'
  end

  def archived?
    status == 'archived'
  end

  def publishable?
    draft? || scheduled?
  end

  def publish!
    update!(status: 'published', published_at: Time.current)
  end

  def unpublish!
    update!(status: 'draft', published_at: nil)
  end

  def archive!
    update!(status: 'archived')
  end

  def status_display
    I18n.t("activerecord.attributes.#{self.class.name.underscore}.statuses.#{status}")
  end
end
```

### 2. Positionable（並び順管理）

```ruby
module Positionable
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order(:position) }
    
    before_create :set_position
  end

  def move_up
    swap_with_previous if previous_item
  end

  def move_down
    swap_with_next if next_item
  end

  def move_to_position(new_position)
    return if new_position == position
    
    transaction do
      if new_position < position
        shift_positions_down(new_position, position - 1)
      else
        shift_positions_up(position + 1, new_position)
      end
      
      update!(position: new_position)
    end
  end

  private

  def set_position
    self.position ||= next_position
  end

  def next_position
    (self.class.maximum(:position) || 0) + 1
  end

  def previous_item
    self.class.where('position < ?', position).ordered.last
  end

  def next_item
    self.class.where('position > ?', position).ordered.first
  end

  def swap_with_previous
    swap_positions(previous_item)
  end

  def swap_with_next
    swap_positions(next_item)
  end

  def swap_positions(other)
    return unless other
    
    transaction do
      other_position = other.position
      other.update!(position: position)
      update!(position: other_position)
    end
  end
end
```

## Service層（22クラス）

### 記事管理サービス

#### ArticleContentManager
```ruby
class ArticleContentManager
  def initialize(article)
    @article = article
  end

  def tech_stack_list
    return [] if @article.tech_stack.blank?
    @article.tech_stack.split(',').map(&:strip)
  end

  def tech_stack_list=(list)
    @article.tech_stack = Array(list).join(', ')
  end

  def is_work?
    @article.categories.exists?(slug: 'works')
  end

  def content_word_count
    @article.content.to_s.split.size
  end

  def content_reading_time
    (content_word_count / 200.0).ceil # 200 words per minute
  end

  def assign_tag_names(names)
    tag_names_array = names.is_a?(String) ? names.split(',').map(&:strip) : Array(names)
    
    tags = tag_names_array.map do |name|
      Tag.find_or_create_by(name: name) do |tag|
        tag.slug = name.parameterize
      end
    end
    
    @article.tags = tags
  end

  def category_names
    @article.categories.pluck(:name).join(', ')
  end

  def tag_names
    @article.tags.pluck(:name).join(', ')
  end
end
```

#### ArticleMetaManager
```ruby
class ArticleMetaManager
  include Rails.application.routes.url_helpers

  def initialize(article)
    @article = article
  end

  def to_param
    @article.slug
  end

  def url_path
    blog_article_path(@article.slug)
  end

  def canonical_url
    blog_article_url(@article.slug, host: default_url_options[:host])
  end

  def seo_title
    @article.meta_title.presence || "#{@article.title} | Portfolio"
  end

  def seo_description
    @article.meta_description.presence || 
    @article.excerpt.presence || 
    truncate(strip_tags(@article.content), length: 160)
  end

  def og_title
    @article.og_title.presence || seo_title
  end

  def og_description
    @article.og_description.presence || seo_description
  end

  def structured_data
    {
      "@context": "https://schema.org",
      "@type": "BlogPosting",
      "headline": @article.title,
      "description": seo_description,
      "datePublished": @article.published_at&.iso8601,
      "dateModified": @article.updated_at.iso8601,
      "author": {
        "@type": "Person",
        "name": @article.admin_user.name
      }
    }.to_json
  end

  def generate_slug
    return if @article.slug.present?
    
    base_slug = @article.title.parameterize
    slug = base_slug
    counter = 1
    
    while Article.where.not(id: @article.id).exists?(slug: slug)
      slug = "#{base_slug}-#{counter}"
      counter += 1
    end
    
    @article.slug = slug
  end

  private

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end
end
```

### セクション管理サービス

#### SectionContentActivationService
```ruby
class SectionContentActivationService
  def initialize(section, version_id)
    @section = section
    @version_id = version_id
  end

  def activate!
    ActiveRecord::Base.transaction do
      # 現在のアクティブバージョンを非アクティブ化
      @section.section_contents.update_all(is_active: false)
      
      # 指定バージョンをアクティブ化
      content = @section.section_contents.find(@version_id)
      content.update!(
        is_active: true,
        published_at: Time.current,
        published_by: Current.admin_user&.id
      )
      
      # キャッシュクリア
      clear_section_cache
      
      content
    end
  rescue ActiveRecord::RecordNotFound
    raise "指定されたバージョンが見つかりません"
  end

  private

  def clear_section_cache
    Rails.cache.delete("section_#{@section.name}_content")
    Rails.cache.delete("portfolio_sections")
  end
end
```

### SEO・メタデータサービス

#### MetaTagsService
```ruby
class MetaTagsService
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper

  def initialize(request, options = {})
    @request = request
    @options = options
    @site_name = 'Miyakawa Portfolio'
  end

  def generate
    tags = []
    
    # 基本メタタグ
    tags << tag(:meta, charset: 'utf-8')
    tags << tag(:meta, name: 'viewport', content: 'width=device-width, initial-scale=1.0')
    
    # SEOメタタグ
    tags << tag(:meta, name: 'description', content: description)
    tags << tag(:meta, name: 'keywords', content: keywords) if keywords.present?
    
    # OGPタグ
    tags << tag(:meta, property: 'og:title', content: og_title)
    tags << tag(:meta, property: 'og:description', content: og_description)
    tags << tag(:meta, property: 'og:type', content: og_type)
    tags << tag(:meta, property: 'og:url', content: canonical_url)
    tags << tag(:meta, property: 'og:site_name', content: @site_name)
    tags << tag(:meta, property: 'og:image', content: og_image) if og_image.present?
    
    # Twitter Card
    tags << tag(:meta, name: 'twitter:card', content: 'summary_large_image')
    tags << tag(:meta, name: 'twitter:title', content: og_title)
    tags << tag(:meta, name: 'twitter:description', content: og_description)
    tags << tag(:meta, name: 'twitter:image', content: og_image) if og_image.present?
    
    # Canonical URL
    tags << tag(:link, rel: 'canonical', href: canonical_url)
    
    safe_join(tags)
  end

  private

  def title
    @options[:title] || 'Miyakawa Portfolio'
  end

  def description
    @options[:description] || 
    'シニアエンジニアの技術発信・ポートフォリオサイト'
  end

  def keywords
    @options[:keywords]
  end

  def og_title
    @options[:og_title] || title
  end

  def og_description
    @options[:og_description] || description
  end

  def og_type
    @options[:og_type] || 'website'
  end

  def og_image
    @options[:og_image]
  end

  def canonical_url
    @options[:canonical_url] || @request.url
  end
end
```

## データベーストランザクション

### 記事の公開処理
```ruby
def publish_article(article)
  ActiveRecord::Base.transaction do
    article.publish!
    article.categories.each(&:touch)
    article.tags.each(&:touch)
    
    # Slack通知
    SlackNotificationJob.perform_later(
      'article_published',
      article.id
    )
  end
end
```

### セクションの更新処理
```ruby
def update_section_content(section, params)
  ActiveRecord::Base.transaction do
    content = section.section_contents.build(params)
    content.save!
    
    if params[:activate]
      SectionContentActivationService
        .new(section, content.id)
        .activate!
    end
    
    content
  end
end
```