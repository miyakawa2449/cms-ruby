module NavigationHelper
  # ページタイトルの生成（レイアウトの<title>で使用）
  # ビュー側の content_for(:title) には「ページ固有部分のみ」を渡すこと。
  # サイト名の付与はここで一元管理する（二重付与の防止）
  def page_title(title = nil, site_name = nil)
    site_name ||= SiteSetting.site_title&.get_value.presence ||
                  SiteSetting.default_for(:site_title)

    if title.present?
      "#{title} | #{site_name}"
    else
      site_name
    end
  end
end
