module TimeHelper
  # 日時処理関連のヘルパーメソッド

  # 相対時間表示（例: "2時間前"）
  def time_ago_in_words_ja(time)
    return "" unless time

    distance = Time.current - time

    case distance
    when 0..59
      "#{distance.to_i}秒前"
    when 60..3599
      "#{(distance / 60).to_i}分前"
    when 3600..86399
      "#{(distance / 3600).to_i}時間前"
    when 86400..604799
      "#{(distance / 86400).to_i}日前"
    when 604800..2629743
      "#{(distance / 604800).to_i}週間前"
    when 2629744..31556925
      "#{(distance / 2629744).to_i}ヶ月前"
    else
      "#{(distance / 31556926).to_i}年前"
    end
  end

  # 記事の公開日時表示
  def article_published_at(article)
    return "下書き" unless article.published?
    return "日時未設定" unless article.published_at

    published_at = article.published_at.in_time_zone("Asia/Tokyo")

    if published_at > 1.week.ago
      time_ago_in_words_ja(published_at)
    else
      published_at.strftime("%Y年%m月%d日")
    end
  end

  # 日付のフォーマット（年月日）
  def format_date_ja(date)
    return "" unless date
    date.strftime("%Y年%m月%d日")
  end

  # 日時のフォーマット（年月日 時分）
  def format_datetime_ja(datetime)
    return "" unless datetime
    datetime.in_time_zone("Asia/Tokyo").strftime("%Y年%m月%d日 %H:%M")
  end

  # 管理画面用の詳細日時表示
  def admin_datetime(datetime)
    return "未設定" unless datetime
    datetime.in_time_zone("Asia/Tokyo").strftime("%Y-%m-%d %H:%M:%S")
  end

  # ISO 8601形式の日時（構造化データ用）
  def iso8601_datetime(datetime)
    return "" unless datetime
    datetime.iso8601
  end
end
