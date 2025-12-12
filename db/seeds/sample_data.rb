# サンプルデータ投入スクリプト
puts "🌱 Starting sample data seeding..."

# Hero セクションのコンテンツ
hero_section = Section.find_by(name: 'hero')
if hero_section && hero_section.section_contents.count == 0
  hero_content = hero_section.section_contents.create!(
    version: 1,
    is_active: true,
    main_message: 'シニアエンジニアの技術発信',
    sub_message: '20年以上の経験を活かした技術ブログとポートフォリオ',
    career_description: 'システムエンジニア・PM として20年以上の経験',
    cta_primary_text: '詳しく見る',
    cta_primary_url: '#about'
  )
  puts "✅ Hero section content created"
end

# About セクションのコンテンツ
about_section = Section.find_by(name: 'about')
if about_section && about_section.section_contents.count == 0
  about_content = about_section.section_contents.create!(
    version: 1,
    is_active: true,
    main_title: 'About Me',
    sub_title: 'シニアエンジニアとしての歩み',
    profile_text: '20年以上のシステムエンジニア経験を持ち、要件定義から実装まで幅広く対応。最近はAI技術との融合に注力し、ChatGPTを活用した開発効率化に取り組んでいます。',
    experience_text: '20年以上',
    core_skills: ['要件定義', 'プロジェクト管理', 'AI活用開発'],
    content: {}
  )
  puts "✅ About section content created"
end

# Service セクションのコンテンツ
service_section = Section.find_by(name: 'service')
if service_section && service_section.section_contents.count == 0
  service_content = service_section.section_contents.create!(
    version: 1,
    is_active: true,
    main_title: 'Services',
    sub_title: '提供できるサービス',
    content: {
      "services" => [
        {
          "title" => '要件定義・設計',
          "description" => 'ビジネス要件を技術要件に落とし込み、最適なシステム設計を提案',
          "icon" => 'design'
        },
        {
          "title" => 'プロジェクト管理',
          "description" => 'アジャイル開発手法を用いた効率的なプロジェクト推進',
          "icon" => 'project'
        },
        {
          "title" => 'AI活用開発',
          "description" => 'ChatGPT等のAI技術を活用した開発効率化・自動化',
          "icon" => 'ai'
        }
      ]
    }
  )
  puts "✅ Service section content created"
end

# My Story セクションのコンテンツ
my_story_section = Section.find_by(name: 'my-story')
if my_story_section && my_story_section.section_contents.count == 0
  my_story_content = my_story_section.section_contents.create!(
    version: 1,
    is_active: true,
    main_title: 'My Story',
    sub_title: '30年のキャリアジャーニー',
    main_message: 'パソコンスクール講師から始まり、SE/PMを経て、AIエンジニアへ。',
    sub_message: '3つのフェーズで歩んできた私のストーリー。',
    cta_primary_text: '詳しいストーリーを読む',
    cta_primary_url: '/my-story',
    phase1_title: 'パソコンスクール講師',
    phase1_year: '1994-2005',
    phase1_period: '11年間',
    phase1_description: '人材育成と教育の基礎を築いた時期',
    phase2_title: 'SE/PM・ビジネス分析者',
    phase2_year: '2005-2021',  
    phase2_period: '16年間',
    phase2_description: '大規模プロジェクトのリードと上流工程専門家として活躍',
    phase3_title: 'AI活用エンジニア',
    phase3_year: '2022-現在',
    phase3_period: '3年間',
    phase3_description: 'ChatGPTとの出会いで新たな技術領域へ挑戦',
    content: {}
  )
  puts "✅ My Story section content created"
end

# サンプル記事の作成
works_category = Category.find_by(name: '実績・作品')
tech_category = Category.find_by(name: '技術ブログ')

# 管理ユーザーを取得
admin_user = AdminUser.first

# Works記事
if works_category && admin_user
  article1 = Article.create!(
    title: 'ECサイトリニューアルプロジェクト',
    content: '大手ECサイトのフルリニューアルプロジェクトを担当。Rails + React + AWSで構築しました。\n\n## プロジェクト概要\n- 期間: 6ヶ月\n- 規模: 開発メンバー15名\n- 技術スタック: Ruby on Rails, React, AWS, PostgreSQL',
    slug: 'ec-site-renewal',
    status: 'published',
    published_at: 1.month.ago,
    admin_user: admin_user,
    work_type: 'github',
    tech_stack: ['Ruby on Rails', 'React', 'AWS', 'PostgreSQL'].join(','),
    github_url: 'https://github.com/miyakawa2449/ec-site-project',
    demo_url: 'https://demo-ec-site.com'
  )
  article1.categories << works_category
  puts "✅ Works article 1 created"

  article2 = Article.create!(
    title: 'AI画像認識システム開発',
    content: '製造業向けの品質検査AI開発プロジェクトを担当。Python + TensorFlow + OpenCVで実装しました。\n\n## システム概要\n- 期間: 4ヶ月\n- 規模: 開発メンバー8名\n- 精度: 99.2%の検査精度を達成',
    slug: 'ai-image-recognition',
    status: 'published',
    published_at: 2.months.ago,
    admin_user: admin_user,
    work_type: 'external_url',
    tech_stack: ['Python', 'TensorFlow', 'OpenCV', 'Docker'].join(','),
    demo_url: 'https://ai-vision-demo.com'
  )
  article2.categories << works_category
  puts "✅ Works article 2 created"

  article3 = Article.create!(
    title: 'このポートフォリオサイト開発',
    content: 'Rails 8.1.1を使用したポートフォリオCMSの開発。セクション管理・ブログ機能・画像管理を実装。\n\n## 技術的な特徴\n- CMS機能による動的コンテンツ管理\n- レスポンシブデザイン\n- SEO最適化\n- API機能',
    slug: 'portfolio-cms-development',
    status: 'published',
    published_at: 1.week.ago,
    admin_user: admin_user,
    work_type: 'github',
    tech_stack: ['Ruby on Rails', 'PostgreSQL', 'Tailwind CSS', 'Stimulus'].join(','),
    github_url: 'https://github.com/miyakawa2449/portfolio_rb'
  )
  article3.categories << works_category
  puts "✅ Works article 3 created"
end

# 技術ブログ記事
if tech_category && admin_user
  blog1 = Article.create!(
    title: 'Rails 8.1の新機能まとめ',
    content: 'Rails 8.1で追加された新機能について詳しく解説します。\n\n## 主要な新機能\n### Solid Queue\n新しいジョブキューシステムで、Redisに依存せずにバックグラウンド処理を実行できます。\n\n### Solid Cache\nアプリケーションキャッシュをSQLiteやPostgreSQLで管理できる新機能です。\n\n### Solid Cable\nActionCableの代替として、データベースベースのWebSocket接続を提供します。',
    slug: 'rails-8-1-new-features',
    status: 'published',
    published_at: 1.week.ago,
    admin_user: admin_user
  )
  blog1.categories << tech_category
  
  # タグを既存のものがあれば使用、なければ作成
  rails_tag = Tag.find_or_create_by!(slug: 'rails') { |t| t.name = 'Rails' }
  ruby_tag = Tag.find_or_create_by!(slug: 'ruby') { |t| t.name = 'Ruby' }
  blog1.tags << [rails_tag, ruby_tag]
  puts "✅ Tech blog article created"

  blog2 = Article.create!(
    title: 'Docker環境でのRails開発効率化',
    content: 'Docker環境での Rails開発における効率化のポイントを解説します。\n\n## 開発環境構築\n### docker-compose.yml の最適化\n開発効率を向上させるための設定方法を詳しく説明します。\n\n### ボリュームマウントの活用\nコードの変更を即座に反映させるための設定です。',
    slug: 'rails-docker-development',
    status: 'published',
    published_at: 2.weeks.ago,
    admin_user: admin_user
  )
  blog2.categories << tech_category
  
  docker_tag = Tag.find_or_create_by!(slug: 'docker') { |t| t.name = 'Docker' }
  dev_tag = Tag.find_or_create_by!(slug: 'development') { |t| t.name = '開発環境' }
  blog2.tags << [rails_tag, docker_tag, dev_tag]
  puts "✅ Tech blog article 2 created"
end

# Contact セクションのコンテンツ
contact_section = Section.find_by(name: 'contact')
if contact_section && contact_section.section_contents.count == 0
  contact_content = contact_section.section_contents.create!(
    version: 1,
    is_active: true,
    main_title: 'Contact',
    sub_title: 'お問い合わせ',
    cta_description: 'プロジェクトのご相談、技術的なご質問など、お気軽にお問い合わせください。',
    content: {}
  )
  puts "✅ Contact section content created"
end

# Footer セクションの作成
footer_section = Section.find_or_create_by!(name: 'footer') do |s|
  s.display_name = 'Footer'
  s.position = 8
  s.is_visible = true
end
puts "✅ Footer section created/found"

# Works セクションのコンテンツ
works_section = Section.find_by(name: 'works')
if works_section && works_section.section_contents.count == 0
  works_content = works_section.section_contents.create!(
    version: 1,
    is_active: true,
    main_title: 'Works',
    sub_title: '実績・作品',
    content: {}
  )
  puts "✅ Works section content created"
end

# Blog セクションのコンテンツ
blog_section = Section.find_by(name: 'blog')
if blog_section && blog_section.section_contents.count == 0
  blog_content = blog_section.section_contents.create!(
    version: 1,
    is_active: true,
    main_title: 'Blog',
    sub_title: '技術ブログ - 最新記事',
    content: {}
  )
  puts "✅ Blog section content created"
end

puts "🚀 Sample data seeding completed successfully!"