module NavigationHelper
  # ナビゲーション関連のヘルパーメソッド

  # パンくずリスト生成
  def breadcrumbs(*links)
    content_tag :nav, class: "flex", 'aria-label': "Breadcrumb" do
      content_tag :ol, class: "inline-flex items-center space-x-1 md:space-x-3" do
        links.map.with_index do |link, index|
          breadcrumb_item(link, index == links.length - 1)
        end.join.html_safe
      end
    end
  end

  # アクティブページの判定
  def current_page?(path)
    request.path == path || request.path.start_with?(path.chomp("/") + "/")
  end

  # ナビゲーションリンクのアクティブクラス
  def nav_link_class(path, base_class = "", active_class = "text-blue-600 font-semibold", inactive_class = "text-gray-700 hover:text-blue-600")
    classes = [ base_class ]
    classes << (current_page?(path) ? active_class : inactive_class)
    classes.join(" ").strip
  end

  # ページタイトルの生成
  def page_title(title = nil, site_name = nil)
    site_name ||= SiteSetting.site_title&.get_value || "Miyakawa Codes"

    if title.present?
      "#{title} | #{site_name}"
    else
      site_name
    end
  end

  # カテゴリナビゲーション
  def category_navigation(current_category = nil)
    categories = Category.with_published_articles.ordered

    content_tag :div, class: "flex flex-wrap gap-2 mb-6" do
      all_link = link_to "すべて", blog_path,
                         class: nav_link_class(blog_path, "px-3 py-1 rounded-full text-sm border")

      category_links = categories.map do |category|
        link_to category.name, blog_path(category: category.slug),
                class: nav_link_class(blog_path(category: category.slug), "px-3 py-1 rounded-full text-sm border")
      end

      ([ all_link ] + category_links).join.html_safe
    end
  end

  # タグクラウド
  def tag_cloud(tags, classes = {})
    return "" if tags.blank?

    max_count = tags.maximum(:article_count) || 1

    content_tag :div, class: "flex flex-wrap gap-2" do
      tags.map do |tag|
        size_class = tag_size_class(tag.article_count, max_count)
        link_to "##{tag.name}", blog_path(tag: tag.slug),
                class: "inline-block px-2 py-1 rounded text-xs #{size_class} #{classes[:base] || 'bg-gray-100 hover:bg-gray-200'}"
      end.join.html_safe
    end
  end

  private

  def breadcrumb_item(link, is_last = false)
    content_tag :li, class: "inline-flex items-center" do
      if is_last
        content_tag :span, link[:text], class: "ml-1 text-sm font-medium text-gray-500 md:ml-2"
      else
        separator = content_tag :svg, class: "w-6 h-6 text-gray-400", fill: "currentColor", viewBox: "0 0 20 20" do
          content_tag :path, "", 'fill-rule': "evenodd", d: "M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z", 'clip-rule': "evenodd"
        end

        link_content = if link[:url]
          link_to link[:text], link[:url], class: "ml-1 text-sm font-medium text-gray-700 hover:text-blue-600 md:ml-2"
        else
          content_tag :span, link[:text], class: "ml-1 text-sm font-medium text-gray-700 md:ml-2"
        end

        (separator + link_content).html_safe
      end
    end
  end

  def tag_size_class(count, max_count)
    ratio = count.to_f / max_count

    case ratio
    when 0.8..1.0
      "text-lg font-bold"
    when 0.6...0.8
      "text-base font-semibold"
    when 0.4...0.6
      "text-sm font-medium"
    else
      "text-xs"
    end
  end
end
