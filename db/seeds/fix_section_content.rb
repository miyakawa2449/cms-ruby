# SectionContent の JSONB content フィールドを正しく設定

puts "Fixing SectionContent data..."

# Hero section
hero_section = Section.find_by(name: 'hero')
if hero_section
  hero_content = hero_section.section_contents.first_or_create!
  hero_content.update!(
    content: {
      "title" => "なぜ要件定義から実装まで<br><span class=\"text-yellow-300\">一人でできる</span>のか？",
      "subtitle" => "30年のキャリアで培った<br>技術力と実装力",
      "lead_text" => "講師から始まり、システムエンジニア、プロジェクトマネージャーを経て、現在はAIエンジニアとして活動。一人で要件定義から実装まで一貫して対応できる理由をお話しします。",
      "cta_text" => "詳しい経歴を見る",
      "cta_url" => "#my-story",
      "background_video" => false,
      "typing_texts" => [
        "要件定義から実装まで一人でできる",
        "30年の経験と技術力",
        "AIエンジニアとして最前線で活動"
      ]
    },
    is_active: true
  )
  puts "✅ Hero section content updated"
end

# About section
about_section = Section.find_by(name: 'about')
if about_section
  about_content = about_section.section_contents.first_or_create!
  about_content.update!(
    content: {
      "title" => "About",
      "subtitle" => "技術者として歩んできた道のり",
      "description" => "1994年からプログラミング講師として始まったキャリア。その後16年間のシステムエンジニア・プロジェクトマネージャー経験を経て、2022年からAIエンジニアとして新たな挑戦を続けています。",
      "profile_image_url" => "/assets/profile.jpg",
      "skills" => [
        {
          "category" => "フロントエンド",
          "items" => [ "HTML/CSS", "JavaScript", "React", "Vue.js", "Tailwind CSS" ]
        },
        {
          "category" => "バックエンド",
          "items" => [ "Ruby on Rails", "Python", "Node.js", "PHP", "Java" ]
        },
        {
          "category" => "AI・機械学習",
          "items" => [ "OpenAI API", "LangChain", "TensorFlow", "PyTorch", "RAG" ]
        },
        {
          "category" => "インフラ・DevOps",
          "items" => [ "AWS", "Docker", "PostgreSQL", "Redis", "CI/CD" ]
        }
      ],
      "experience_years" => 30,
      "projects_completed" => "100+"
    },
    is_active: true
  )
  puts "✅ About section content updated"
end

# Service section
service_section = Section.find_by(name: 'service')
if service_section
  service_content = service_section.section_contents.first_or_create!
  service_content.update!(
    content: {
      "title" => "Services",
      "subtitle" => "提供できるサービス",
      "services" => [
        {
          "title" => "要件定義・設計",
          "description" => "ビジネス要件の整理から技術仕様の策定まで、プロジェクト全体の設計を行います。",
          "icon" => "document-text",
          "features" => [ "要件分析", "システム設計", "DB設計", "API設計" ]
        },
        {
          "title" => "フルスタック開発",
          "description" => "フロントエンドからバックエンドまで、一貫した開発を提供します。",
          "icon" => "code",
          "features" => [ "React/Vue.js", "Ruby on Rails", "REST API", "データベース" ]
        },
        {
          "title" => "AI システム開発",
          "description" => "生成AI・機械学習を活用したシステムの企画・開発を行います。",
          "icon" => "cog",
          "features" => [ "OpenAI API", "RAG システム", "チャットボット", "自動化" ]
        },
        {
          "title" => "技術コンサルティング",
          "description" => "技術選定から開発プロセス改善まで、包括的な技術支援を提供します。",
          "icon" => "academic-cap",
          "features" => [ "技術選定", "アーキテクチャ", "コードレビュー", "教育・研修" ]
        }
      ]
    },
    is_active: true
  )
  puts "✅ Service section content updated"
end

# My Story section
my_story_section = Section.find_by(name: 'my-story')
if my_story_section
  my_story_content = my_story_section.section_contents.first_or_create!
  my_story_content.update!(
    content: {
      "title" => "My Story",
      "subtitle" => "30年のキャリアで培った技術と経験",
      "lead_text" => "講師として始まり、システムエンジニア、プロジェクトマネージャーを経て、現在はAIエンジニアとして活動するまでの軌跡をご紹介します。",
      "cta_text" => "詳しいストーリーを見る",
      "cta_url" => "/my-story",
      "timeline_data" => [
        {
          "period" => "1994-2005",
          "title" => "講師時代",
          "description" => "プログラミング講師として基礎を築く"
        },
        {
          "period" => "2005-2021",
          "title" => "SE・PM時代",
          "description" => "大規模システム開発の最前線で活動"
        },
        {
          "period" => "2022-現在",
          "title" => "AIエンジニア時代",
          "description" => "AI技術で新たな価値創造に挑戦"
        }
      ]
    },
    is_active: true
  )
  puts "✅ My Story section content updated"
end

puts "SectionContent data fix completed!"
