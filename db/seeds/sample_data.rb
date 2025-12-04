# Sample data for development
puts "🌱 Creating sample data..."

# タグの作成
puts "📏 Creating tags..."
tags = [
  { name: "Ruby", slug: "ruby" },
  { name: "Rails", slug: "rails" },
  { name: "PostgreSQL", slug: "postgresql" },
  { name: "Docker", slug: "docker" },
  { name: "API設計", slug: "api-design" },
  { name: "セキュリティ", slug: "security" },
  { name: "パフォーマンス", slug: "performance" },
  { name: "AI・機械学習", slug: "ai-ml" }
]

created_tags = tags.map do |tag_attrs|
  Tag.find_or_create_by!(slug: tag_attrs[:slug]) do |tag|
    tag.name = tag_attrs[:name]
  end
end

# カテゴリの作成
puts "📂 Creating categories..."
categories = [
  {
    name: "開発技術",
    slug: "development",
    description: "プログラミング・開発技術に関する記事",
    color: "#3B82F6",
    icon: "code"
  },
  {
    name: "インフラ・DevOps",
    slug: "infrastructure",
    description: "インフラストラクチャ・DevOpsに関する記事",
    color: "#10B981",
    icon: "server"
  },
  {
    name: "プロジェクト管理",
    slug: "project-management",
    description: "プロジェクト管理・チーム開発に関する記事",
    color: "#F59E0B",
    icon: "users"
  }
]

created_categories = categories.map do |cat_attrs|
  Category.find_or_create_by!(slug: cat_attrs[:slug]) do |category|
    category.name = cat_attrs[:name]
    category.description = cat_attrs[:description]
    category.color = cat_attrs[:color]
    category.icon = cat_attrs[:icon]
  end
end

# サブカテゴリの作成
puts "📁 Creating subcategories..."
subcategories = [
  {
    parent: "development",
    name: "バックエンド開発",
    slug: "backend",
    description: "サーバーサイド開発に関する記事",
    color: "#6366F1"
  },
  {
    parent: "development",
    name: "フロントエンド開発",
    slug: "frontend",
    description: "クライアントサイド開発に関する記事",
    color: "#EC4899"
  },
  {
    parent: "infrastructure",
    name: "コンテナ技術",
    slug: "container",
    description: "Docker・Kubernetesなどコンテナ技術",
    color: "#0EA5E9"
  }
]

subcategories.each do |sub_attrs|
  parent = Category.find_by!(slug: sub_attrs[:parent])
  Category.find_or_create_by!(slug: sub_attrs[:slug], parent: parent) do |category|
    category.name = sub_attrs[:name]
    category.description = sub_attrs[:description]
    category.color = sub_attrs[:color]
    category.parent = parent
  end
end

# 記事の作成
puts "📝 Creating articles..."
articles = [
  {
    title: "Rails 8.1で始めるモダンWeb開発",
    slug: "rails-8-1-modern-web-development",
    content: "# Rails 8.1で始めるモダンWeb開発\n\nRails 8.1では、多くの新機能が追加されました。特に注目すべきは以下の点です：\n\n## 1. Hotwire統合の強化\n\nTurboとStimulusがデフォルトで統合され、SPAのようなユーザー体験を簡単に実現できます。\n\n```ruby\n# Turbo Streamsを使用したリアルタイム更新\nturbo_stream.append \"messages\" do\n  render partial: \"message\", locals: { message: @message }\nend\n```\n\n## 2. Active Job Continuations\n\n長時間実行されるジョブを複数のステップに分割して実行できるようになりました。\n\n## 3. Solid Queue統合\n\nRedis不要のジョブキューシステムが標準搭載されました。",
    excerpt: "Rails 8.1の新機能と、それを活用したモダンなWeb開発手法について解説します。",
    status: "published",
    published_at: 2.days.ago,
    categories: [Category.find_by(slug: "backend")],
    tags: [Tag.find_by(slug: "ruby"), Tag.find_by(slug: "rails")]
  },
  {
    title: "PostgreSQL 17の新機能とパフォーマンス改善",
    slug: "postgresql-17-new-features",
    content: "# PostgreSQL 17の新機能とパフォーマンス改善\n\nPostgreSQL 17がリリースされ、多くの改善が行われました。\n\n## 主な新機能\n\n### 1. パフォーマンス向上\n- B-treeインデックスの改善\n- パーティションテーブルのクエリ性能向上\n- 並列処理の強化\n\n### 2. JSON機能の拡張\n```sql\n-- 新しいJSON関数の例\nSELECT jsonb_path_query_array(data, '$.items[*].price') \nFROM products;\n```\n\n### 3. セキュリティ強化\n- 新しい認証方式のサポート\n- 監査機能の改善",
    excerpt: "PostgreSQL 17の新機能と、実際のプロジェクトでの活用方法を紹介します。",
    status: "published",
    published_at: 5.days.ago,
    categories: [Category.find_by(slug: "infrastructure")],
    tags: [Tag.find_by(slug: "postgresql"), Tag.find_by(slug: "performance")]
  },
  {
    title: "DockerでRails開発環境を構築する完全ガイド",
    slug: "docker-rails-development-guide",
    content: "# DockerでRails開発環境を構築する完全ガイド\n\n## なぜDockerを使うのか\n\n開発環境の統一、依存関係の管理、本番環境との差異を最小限にするために、Dockerは非常に有効です。\n\n## docker-compose.ymlの設定\n\n```yaml\nservices:\n  db:\n    image: postgres:17-alpine\n    environment:\n      POSTGRES_DB: myapp_development\n      POSTGRES_USER: myapp\n      POSTGRES_PASSWORD: password\n  web:\n    build: .\n    command: bundle exec rails server -b 0.0.0.0\n    volumes:\n      - .:/app\n    ports:\n      - \"3000:3000\"\n    depends_on:\n      - db\n```\n\n## ベストプラクティス\n\n1. Alpine Linuxベースのイメージを使用\n2. マルチステージビルドで軽量化\n3. 開発用と本番用でDockerfileを分ける",
    excerpt: "DockerとDocker Composeを使用して、Rails開発環境を効率的に構築する方法を解説します。",
    status: "published",
    published_at: 7.days.ago,
    categories: [Category.find_by(slug: "container")],
    tags: [Tag.find_by(slug: "docker"), Tag.find_by(slug: "rails")]
  },
  {
    title: "RESTful API設計のベストプラクティス",
    slug: "restful-api-best-practices",
    content: "# RESTful API設計のベストプラクティス\n\n## 1. リソース指向の設計\n\nAPIはリソースを中心に設計します。\n\n```\nGET    /api/v1/articles      # 記事一覧\nGET    /api/v1/articles/:id  # 記事詳細\nPOST   /api/v1/articles      # 記事作成\nPATCH  /api/v1/articles/:id  # 記事更新\nDELETE /api/v1/articles/:id  # 記事削除\n```\n\n## 2. HTTPステータスコードの適切な使用\n\n- 200 OK: 成功\n- 201 Created: リソース作成成功\n- 400 Bad Request: リクエスト不正\n- 401 Unauthorized: 認証エラー\n- 404 Not Found: リソースが見つからない\n\n## 3. ページネーション\n\n大量のデータを扱う場合は必須です。",
    excerpt: "実践的なRESTful API設計の原則とRailsでの実装方法について説明します。",
    status: "published",
    published_at: 10.days.ago,
    categories: [Category.find_by(slug: "backend")],
    tags: [Tag.find_by(slug: "api-design"), Tag.find_by(slug: "rails")]
  },
  {
    title: "AIを活用した開発効率化の実践",
    slug: "ai-powered-development",
    content: "# AIを活用した開発効率化の実践\n\n## GitHub Copilotの活用\n\nコード補完だけでなく、テストコードの生成やドキュメント作成にも活用できます。\n\n## ChatGPT/Claude APIの統合\n\n```ruby\nclass AiService\n  def generate_summary(text)\n    client = OpenAI::Client.new\n    response = client.chat(\n      parameters: {\n        model: \"gpt-4\",\n        messages: [\n          { role: \"system\", content: \"要約を生成してください\" },\n          { role: \"user\", content: text }\n        ]\n      }\n    )\n    response.dig(\"choices\", 0, \"message\", \"content\")\n  end\nend\n```\n\n## 開発プロセスへの統合\n\n1. コードレビューの補助\n2. ドキュメント生成\n3. テストケース作成",
    excerpt: "AI技術を開発プロセスに統合し、生産性を向上させる具体的な方法を紹介します。",
    status: "draft",
    published_at: nil,
    categories: [Category.find_by(slug: "development")],
    tags: [Tag.find_by(slug: "ai-ml")]
  }
]

articles.each do |article_attrs|
  tags = article_attrs.delete(:tags)
  categories = article_attrs.delete(:categories)
  
  article = Article.find_or_create_by!(slug: article_attrs[:slug]) do |a|
    a.attributes = article_attrs
    a.admin_user = AdminUser.first
  end
  
  article.categories = categories if categories&.any?
  article.tags = tags if tags&.any?
end

# セクションの作成
puts "📍 Creating sections..."
sections = [
  { name: "hero", display_name: "ヒーロー", position: 1, is_visible: true },
  { name: "about", display_name: "自己紹介", position: 2, is_visible: true },
  { name: "skills", display_name: "スキル", position: 3, is_visible: true },
  { name: "services", display_name: "サービス", position: 4, is_visible: true },
  { name: "my-story", display_name: "My Story", position: 5, is_visible: true },
  { name: "works", display_name: "実績", position: 6, is_visible: true },
  { name: "blog", display_name: "ブログ", position: 7, is_visible: true },
  { name: "contact", display_name: "お問い合わせ", position: 8, is_visible: true }
]

sections.each do |section_attrs|
  Section.find_or_create_by!(name: section_attrs[:name]) do |section|
    section.display_name = section_attrs[:display_name]
    section.position = section_attrs[:position]
    section.is_visible = section_attrs[:is_visible]
  end
end

# セクションコンテンツの作成
puts "📄 Creating section contents..."
hero_section = Section.find_by(name: "hero")
if hero_section
  SectionContent.find_or_create_by!(
    section: hero_section,
    version: 1
  ) do |content|
    content.content = {
      title: "宮川剛のポートフォリオ",
      subtitle: "要件定義からプログラミングまで一人でできるエンジニア",
      background_image: "/images/hero-bg.jpg",
      cta_text: "詳しく見る",
      cta_link: "#about"
    }
    content.is_active = true
  end
end

about_section = Section.find_by(name: "about")
if about_section
  SectionContent.find_or_create_by!(
    section: about_section,
    version: 1
  ) do |content|
    content.content = {
      title: "About Me",
      description: "20年以上のシステムエンジニア経験を持ち、要件定義から実装まで一貫して担当できるフルスタックエンジニアです。",
      skills: ["Ruby on Rails", "PostgreSQL", "Docker", "AWS", "AI活用"],
      experience_years: 20
    }
    content.is_active = true
  end
end

puts "✅ Sample data created successfully!"
puts "📊 Summary:"
puts "  - Tags: #{Tag.count}"
puts "  - Categories: #{Category.count}"
puts "  - Articles: #{Article.count} (Published: #{Article.where(status: 'published').count})"
puts "  - Sections: #{Section.count}"
puts "  - Section Contents: #{SectionContent.count}"