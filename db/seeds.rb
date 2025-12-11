# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting database seeding..."

# Create AdminUser for development/test
admin = AdminUser.find_or_create_by!(email: "admin@portfolio.dev") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "✅ AdminUser created: #{admin.email}"
puts "🎯 Password: password123"

# 実績・作品カテゴリを作成
works_category = Category.find_or_create_by!(slug: 'works') do |category|
  category.name = '実績・作品'
  category.description = 'プロジェクト実績やポートフォリオ作品を紹介'
  category.color = '#8B5CF6'  # Purple
  category.parent_id = nil
end

puts "✅ Works category created: #{works_category.name}"

# 他の基本カテゴリも作成
categories = [
  { name: '技術ブログ', slug: 'tech-blog', description: '技術情報や開発ノウハウを共有', color: '#3B82F6' },
  { name: '開発ログ', slug: 'dev-log', description: '開発プロセスや学習記録', color: '#10B981' },
  { name: '雑記', slug: 'misc', description: 'その他の話題', color: '#6B7280' }
]

categories.each do |category_data|
  category = Category.find_or_create_by!(slug: category_data[:slug]) do |cat|
    cat.name = category_data[:name]
    cat.description = category_data[:description]
    cat.color = category_data[:color]
    cat.parent_id = nil
  end
  puts "✅ Category created: #{category.name}"
end

# セクションを作成
sections = [
  { name: 'hero', display_name: 'ヒーロー', position: 1 },
  { name: 'about', display_name: 'About', position: 2 },
  { name: 'service', display_name: 'Service', position: 3 },
  { name: 'my-story', display_name: 'My Story', position: 4 },
  { name: 'works', display_name: 'Works', position: 5 },
  { name: 'blog', display_name: 'Blog', position: 6 },
  { name: 'contact', display_name: 'Contact', position: 7 }
]

sections.each do |section_data|
  section = Section.find_or_create_by!(name: section_data[:name]) do |sec|
    sec.display_name = section_data[:display_name]
    sec.position = section_data[:position]
    sec.is_visible = true
  end
  puts "✅ Section created: #{section.display_name}"
end

puts "🚀 Seeding completed successfully!"
