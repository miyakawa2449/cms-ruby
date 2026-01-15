# My Story Section Sample Data

puts "Creating My Story sections..."

# Hero Section
hero = MyStorySection.find_or_create_by(section_type: 'hero') do |section|
  section.title = "シニアエンジニアが歩んできた道"
  section.subtitle = "講師から開発現場、そしてAIの最前線へ"
  section.content = "30年にわたる技術者人生で培った経験と知見を、次世代のエンジニアたちに繋げていきたい。"
  section.position = 1
  section.is_active = true
end

# Timeline Section
timeline = MyStorySection.find_or_create_by(section_type: 'timeline') do |section|
  section.title = "キャリアタイムライン"
  section.subtitle = "3つのフェーズで振り返る成長の軌跡"
  section.content = "1994年から現在まで、講師・エンジニア・AIエンジニアという3つの役割を通じて培ってきた技術と経験。"
  section.position = 2
  section.is_active = true
  section.additional_data = {
    timeline_years: [ "1994-2005", "2005-2021", "2022-現在" ]
  }
end

# Chapter 1: 講師時代 (1994-2005)
chapter1 = MyStorySection.find_or_create_by(section_type: 'chapter_1') do |section|
  section.title = "第1章: 講師時代 (1994-2005)"
  section.subtitle = "基礎から応用まで、教えることで学ぶ"
  section.content = <<~CONTENT
    プログラミング講師として11年間、多くの受講生に技術を教えながら、
    自らも成長し続けた時代。基礎知識の重要性と、
    相手の立場に立って説明することの大切さを学びました。
  CONTENT
  section.skills = <<~SKILLS
    課題の明確化・分析
    モチベーション維持・管理
    体系的な知識整理
    分かりやすい説明技術
    継続的学習の習慣化
  SKILLS
  section.achievements = <<~ACHIEVEMENTS
    年間200名以上の受講生指導
    カリキュラム設計・改善
    新人講師の育成・指導
    企業研修プログラム開発
  ACHIEVEMENTS
  section.quote = "「教えることは、最も効果的な学習方法である」この信念が、現在の技術力の礎となっています。"
  section.position = 3
  section.is_active = true
end

# Chapter 2: システムエンジニア・プロジェクトマネージャー時代 (2005-2021)
chapter2 = MyStorySection.find_or_create_by(section_type: 'chapter_2') do |section|
  section.title = "第2章: SE・PM時代 (2005-2021)"
  section.subtitle = "現場で磨かれた実践力とリーダーシップ"
  section.content = <<~CONTENT
    システム開発の最前線で16年間、様々なプロジェクトに携わりました。
    技術的な課題解決だけでなく、チームマネジメントや
    顧客との調整など、総合的なスキルを身につけた期間です。
  CONTENT
  section.skills = <<~SKILLS
    大規模システム設計・開発
    プロジェクトマネジメント
    チームリーダーシップ
    顧客折衝・要件定義
    品質管理・リスク管理
  SKILLS
  section.achievements = <<~ACHIEVEMENTS
    金融システム基盤構築プロジェクト（PM）
    ECサイト刷新プロジェクト（テックリード）
    社内システム統合プロジェクト（アーキテクト）
    アジャイル開発プロセス導入・推進
  ACHIEVEMENTS
  section.quote = "「技術は人を幸せにするためのツール」システム開発を通じて、多くの人の生活を便利にできることに深いやりがいを感じていました。"
  section.position = 4
  section.is_active = true
end

# Chapter 3: AIエンジニア時代 (2022-現在)
chapter3 = MyStorySection.find_or_create_by(section_type: 'chapter_3') do |section|
  section.title = "第3章: AIエンジニア時代 (2022-現在)"
  section.subtitle = "新しい技術領域への挑戦と成長"
  section.content = <<~CONTENT
    AI技術の急速な発展とともに、新たな分野への挑戦を決意。
    これまでの経験を活かしながら、機械学習・生成AI・LLM活用の
    専門性を身につけ、技術の最前線で価値創造に取り組んでいます。
  CONTENT
  section.skills = <<~SKILLS
    機械学習・深層学習
    LLM・生成AI活用
    プロンプトエンジニアリング
    AI システム設計・構築
    データ分析・可視化
  SKILLS
  section.achievements = <<~ACHIEVEMENTS
    社内AIチャットボット開発・運用
    業務自動化システム構築（Python・OpenAI API）
    RAGシステム設計・実装
    AI活用研修・コンサルティング
  ACHIEVEMENTS
  section.quote = "「AIは人間の能力を拡張する技術」既存の知識と経験にAIを組み合わせることで、これまでにない価値を生み出せると確信しています。"
  section.position = 5
  section.is_active = true
end

# Projects Section
projects = MyStorySection.find_or_create_by(section_type: 'projects') do |section|
  section.title = "主要プロジェクト実績"
  section.subtitle = "技術と経験が結実した代表的な取り組み"
  section.content = "各時代を代表する3つのプロジェクトをご紹介します。"
  section.position = 6
  section.is_active = true
  section.additional_data = {
    projects: [
      {
        title: "企業向けAIチャットボット",
        description: "社内問い合わせ対応を自動化するRAGシステム",
        period: "2024年",
        scale: "月間1,000件の問い合わせを95%自動対応",
        technologies: [ "Python", "OpenAI API", "PostgreSQL", "Docker" ]
      },
      {
        title: "金融システム基盤構築",
        description: "高可用性を要求される金融機関向けシステム",
        period: "2018-2020年",
        scale: "100万ユーザー対応・99.99%可用性達成",
        technologies: [ "Java", "Spring Boot", "Oracle", "AWS" ]
      },
      {
        title: "プログラミング教育カリキュラム",
        description: "初心者向け体系的学習プログラム",
        period: "2000-2005年",
        scale: "累計1,000名以上の卒業生",
        technologies: [ "C", "Java", "SQL", "Web技術" ]
      }
    ]
  }
end

# CTA Section
cta = MyStorySection.find_or_create_by(section_type: 'cta') do |section|
  section.title = "一緒に未来を創りませんか"
  section.subtitle = "新しい技術で、新しい価値を"
  section.content = <<~CONTENT
    30年間の技術者人生で培った経験と、AI時代の最新スキルを活かして、
    あなたのプロジェクトに貢献したいと考えています。
    技術相談からシステム開発まで、お気軽にご相談ください。
  CONTENT
  section.position = 7
  section.is_active = true
  section.additional_data = {
    cta_buttons: [
      {
        text: "お問い合わせ",
        url: "/contact",
        style: "primary"
      },
      {
        text: "実績を見る",
        url: "/works",
        style: "secondary"
      }
    ]
  }
end

puts "My Story sections created successfully!"
puts "- Hero: #{hero.title}"
puts "- Timeline: #{timeline.title}"
puts "- Chapter 1: #{chapter1.title}"
puts "- Chapter 2: #{chapter2.title}"
puts "- Chapter 3: #{chapter3.title}"
puts "- Projects: #{projects.title}"
puts "- CTA: #{cta.title}"
