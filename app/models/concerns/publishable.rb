# frozen_string_literal: true

module Publishable
  extend ActiveSupport::Concern

  included do
    scope :published, -> { where(status: "published") }
    scope :draft, -> { where(status: "draft") }
    scope :visible, -> { where(is_visible: true) }
  end

  # 公開状態判定
  def published?
    case
    when respond_to?(:status)
      status == "published" && (respond_to?(:published_at) ? (published_at.nil? || published_at <= Time.current) : true)
    when respond_to?(:is_active)
      is_active?
    when respond_to?(:is_visible)
      is_visible?
    when respond_to?(:active_content)
      active_content.present?
    else
      true
    end
  end

  def draft?
    case
    when respond_to?(:status)
      status == "draft"
    when respond_to?(:is_active)
      !is_active?
    when respond_to?(:is_visible)
      !is_visible?
    else
      false
    end
  end

  def archived?
    respond_to?(:status) && status == "archived"
  end

  def scheduled?
    respond_to?(:status) && status == "scheduled"
  end

  # 公開可能かチェック
  def publishable?
    case
    when respond_to?(:title) && respond_to?(:content)
      title.present? && content.present?
    when respond_to?(:name)
      name.present?
    else
      true
    end
  end

  # ステータス表示用
  def status_display
    case
    when respond_to?(:status)
      case status
      when "published"
        (published_at && published_at > Time.current) ? "予約公開" : "公開中"
      when "draft"
        "下書き"
      when "scheduled"
        "予約済み"
      when "archived"
        "アーカイブ"
      else
        status.humanize
      end
    when respond_to?(:is_active)
      is_active? ? "有効" : "無効"
    when respond_to?(:is_visible)
      is_visible? ? "表示中" : "非表示"
    else
      "不明"
    end
  end

  # 公開状態切り替え
  def toggle_published!
    case
    when respond_to?(:status)
      new_status = published? ? "draft" : "published"
      update!(status: new_status, published_at: (new_status == "published" ? Time.current : nil))
    when respond_to?(:is_active)
      update!(is_active: !is_active)
    when respond_to?(:is_visible)
      update!(is_visible: !is_visible)
    else
      false
    end
  end

  # 公開日時設定
  def set_published_at!
    return unless respond_to?(:published_at) && published?

    update!(published_at: Time.current) if published_at.blank?
  end
end
