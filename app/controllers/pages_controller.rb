class PagesController < ApplicationController
  include SeoHelper
  
  # GET /
  def portfolio
    # SEOメタ情報を設定
    page_title "宮川 剛 - ポートフォリオ"
    meta_description "30年のキャリアを持つシニアエンジニア宮川剛のポートフォリオ。Ruby on Rails、AI活用、要件定義から実装まで一貫した技術力を紹介。"
    meta_keywords ["宮川剛", "ポートフォリオ", "シニアエンジニア", "Ruby on Rails", "AI活用", "要件定義", "プロジェクト管理"]
    
    set_og_tags(
      title: "宮川 剛 - シニアエンジニアのポートフォリオ",
      description: "30年の経験を活かした技術発信",
      type: 'website'
    )
    
    # ポートフォリオページのロジック
    # 必要に応じてデータベースから実績データを取得
    # @projects = Project.published.order(created_at: :desc)
    # @skills = Skill.all.group_by(&:category)
    # @experiences = Experience.order(start_date: :desc)
  end

  # GET /my-story
  def my_story
    # SEOメタ情報を設定
    page_title "My Story - 30年のキャリア軌跡"
    meta_description "パソコンスクール講師からSE/PM、そしてAI活用エンジニアへ。宮川剛の30年にわたるIT業界でのキャリアストーリー。なぜ要件定義から実装まで一人でできるのか、その理由がここに。"
    meta_keywords ["My Story", "キャリア", "SE", "PM", "AI活用", "ChatGPT", "要件定義", "プロジェクト管理"]
    
    set_og_tags(
      title: "My Story - 宮川剛の30年のキャリア軌跡",
      description: "要件定義から実装まで一人でできる理由"
    )
    
    # My Storyページのロジック
    # @career_phases = [
    #   { phase: 1, period: "1994-2005", title: "パソコンスクール講師時代", ... },
    #   { phase: 2, period: "2005-2021", title: "SE/PM・ビジネス分析者時代", ... },
    #   { phase: 3, period: "2022-現在", title: "AI活用エンジニア時代", ... }
    # ]
  end
end