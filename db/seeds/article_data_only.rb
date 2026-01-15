# Article データのみ投入スクリプト
puts "🌱 Starting article data seeding..."

# サンプル記事の作成
works_category = Category.find_by(name: '実績・作品')
tech_category = Category.find_by(name: '技術ブログ')

# 管理ユーザーを取得
admin_user = AdminUser.first

# Works記事
if works_category && admin_user && Article.where(slug: 'ec-site-renewal').count == 0
  article1 = Article.create!(
    title: 'ECサイトリニューアルプロジェクト',
    content: '大手ECサイトのフルリニューアルプロジェクトを担当。Rails + React + AWSで構築しました。\n\n## プロジェクト概要\n- 期間: 6ヶ月\n- 規模: 開発メンバー15名\n- 技術スタック: Ruby on Rails, React, AWS, PostgreSQL',
    slug: 'ec-site-renewal',
    status: 'published',
    published_at: 1.month.ago,
    admin_user: admin_user,
    work_type: 'github',
    tech_stack: [ 'Ruby on Rails', 'React', 'AWS', 'PostgreSQL' ].join(','),
    github_url: 'https://github.com/miyakawa2449/ec-site-project',
    demo_url: 'https://demo-ec-site.com'
  )
  article1.categories << works_category
  puts "✅ Works article 1 created"
end

if works_category && admin_user && Article.where(slug: 'ai-image-recognition').count == 0
  article2 = Article.create!(
    title: 'AI画像認識システム開発',
    content: '製造業向けの品質検査AI開発プロジェクトを担当。Python + TensorFlow + OpenCVで実装しました。\n\n## システム概要\n- 期間: 4ヶ月\n- 規模: 開発メンバー8名\n- 精度: 99.2%の検査精度を達成',
    slug: 'ai-image-recognition',
    status: 'published',
    published_at: 2.months.ago,
    admin_user: admin_user,
    work_type: 'external_url',
    tech_stack: [ 'Python', 'TensorFlow', 'OpenCV', 'Docker' ].join(','),
    demo_url: 'https://ai-vision-demo.com'
  )
  article2.categories << works_category
  puts "✅ Works article 2 created"
end

if works_category && admin_user && Article.where(slug: 'portfolio-cms-development').count == 0
  article3 = Article.create!(
    title: 'このポートフォリオサイト開発',
    content: 'Rails 8.1.1を使用したポートフォリオCMSの開発。セクション管理・ブログ機能・画像管理を実装。\n\n## 技術的な特徴\n- CMS機能による動的コンテンツ管理\n- レスポンシブデザイン\n- SEO最適化\n- API機能',
    slug: 'portfolio-cms-development',
    status: 'published',
    published_at: 1.week.ago,
    admin_user: admin_user,
    work_type: 'github',
    tech_stack: [ 'Ruby on Rails', 'PostgreSQL', 'Tailwind CSS', 'Stimulus' ].join(','),
    github_url: 'https://github.com/miyakawa2449/portfolio_rb'
  )
  article3.categories << works_category
  puts "✅ Works article 3 created"
end

# 技術ブログ記事
if tech_category && admin_user && Article.where(slug: 'rails-8-1-new-features').count == 0
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
  blog1.tags << [ rails_tag, ruby_tag ]
  puts "✅ Tech blog article created"
end

if tech_category && admin_user && Article.where(slug: 'rails-docker-development').count == 0
  blog2 = Article.create!(
    title: 'Docker環境でのRails開発効率化',
    content: 'Docker環境での Rails開発における効率化のポイントを解説します。\n\n## 開発環境構築\n### docker-compose.yml の最適化\n開発効率を向上させるための設定方法を詳しく説明します。\n\n### ボリュームマウントの活用\nコードの変更を即座に反映させるための設定です。',
    slug: 'rails-docker-development',
    status: 'published',
    published_at: 2.weeks.ago,
    admin_user: admin_user
  )
  blog2.categories << tech_category

  rails_tag = Tag.find_or_create_by!(slug: 'rails') { |t| t.name = 'Rails' }
  docker_tag = Tag.find_or_create_by!(slug: 'docker') { |t| t.name = 'Docker' }
  dev_tag = Tag.find_or_create_by!(slug: 'development') { |t| t.name = '開発環境' }
  blog2.tags << [ rails_tag, docker_tag, dev_tag ]
  puts "✅ Tech blog article 2 created"
end

puts "🚀 Article data seeding completed successfully!"
