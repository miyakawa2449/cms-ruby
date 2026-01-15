module ApplicationHelper
  # 他のヘルパーモジュールをインクルード
  include MarkdownHelper
  include SectionHelper
  include TimeHelper
  include NavigationHelper
  include GtmHelper

  # アプリケーション全体で使用する基本的なヘルパーメソッド

  # フラッシュメッセージのCSSクラス
  def flash_class(type)
    case type.to_sym
    when :notice
      "bg-green-100 border-green-500 text-green-700"
    when :alert
      "bg-red-100 border-red-500 text-red-700"
    when :error
      "bg-red-100 border-red-500 text-red-700"
    when :warning
      "bg-yellow-100 border-yellow-500 text-yellow-700"
    else
      "bg-blue-100 border-blue-500 text-blue-700"
    end
  end

  # 環境表示用ヘルパー
  def environment_badge
    return unless Rails.env.development? || Rails.env.staging?

    content_tag :div,
                Rails.env.upcase,
                class: "fixed top-0 right-0 z-50 bg-#{Rails.env.development? ? 'green' : 'yellow'}-500 text-white px-2 py-1 text-xs"
  end
end
