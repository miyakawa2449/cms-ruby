# 初期セクションデータの作成スクリプト

sections = [
  {
    name: "hero",
    title: "Hero Section",
    content: {
      title: "宮川 剛",
      subtitle: "シニアエンジニア / プロジェクトマネージャー",
      description: "20年以上の開発経験を持つフルスタックエンジニア。要件定義から実装まで一貫して対応可能。",
      cta_text: "お問い合わせ",
      cta_url: "#contact"
    }
  },
  {
    name: "about",
    title: "About Me",
    content: {
      title: "私について",
      description: "システムエンジニア・プロジェクトマネージャーとして20年以上の経験を持ち、上流工程から下流工程まで幅広く対応可能なエンジニアです。",
      skills: ["Ruby on Rails", "PostgreSQL", "Docker", "AWS", "プロジェクト管理"],
      experience_years: 20
    }
  },
  {
    name: "services",
    title: "Services",
    content: {
      title: "提供サービス",
      items: [
        {
          title: "システム開発",
          description: "要件定義から実装まで一貫したサービス提供",
          icon: "code"
        },
        {
          title: "技術コンサルティング",
          description: "技術選定や開発プロセスの最適化支援",
          icon: "consulting"
        },
        {
          title: "プロジェクト管理",
          description: "大規模プロジェクトの管理・推進支援",
          icon: "management"
        }
      ]
    }
  },
  {
    name: "contact",
    title: "Contact",
    content: {
      title: "お問い合わせ",
      description: "お仕事のご依頼・ご相談はこちらからお願いします。",
      form_fields: ["name", "email", "message"]
    }
  }
]

sections.each do |section_data|
  Section.create!(
    name: section_data[:name],
    title: section_data[:title],
    content: section_data[:content],
    position: Section.maximum(:position).to_i + 1,
    is_active: true
  )
  puts "Created section: #{section_data[:name]}"
end

puts "Initial sections created successfully!"