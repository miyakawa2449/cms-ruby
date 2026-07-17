# frozen_string_literal: true

module Admin
  module ArticlesHelper
    # 記事ステータスバッジの定義（S1-7 P3-6でビューのcase文コピペを一元化）
    ARTICLE_STATUS_BADGES = {
      "published" => { label: "公開中", classes: "bg-green-100 text-green-800" },
      "draft" => { label: "下書き", classes: "bg-yellow-100 text-yellow-800" },
      "scheduled" => { label: "予約投稿", classes: "bg-blue-100 text-blue-800" },
      "archived" => { label: "アーカイブ", classes: "bg-gray-100 text-gray-800" }
    }.freeze

    def article_status_badge(article)
      badge = ARTICLE_STATUS_BADGES[article.status]
      return "" unless badge

      content_tag(
        :span,
        badge[:label],
        class: "px-2 inline-flex text-xs leading-5 font-semibold rounded-full #{badge[:classes]}"
      )
    end
  end
end
