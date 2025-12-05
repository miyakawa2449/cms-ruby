namespace :portfolio do
  desc "Create sample section contents for testing"
  task create_sample_content: :environment do
    admin_user = AdminUser.first
    
    if admin_user.nil?
      puts "❌ Admin user not found. Please run rails db:seed first."
      exit
    end
    
    # Heroセクションのサンプルコンテンツ
    hero_section = Section.find_by(name: 'hero')
    if hero_section
      hero_content = {
        title: "シニアエンジニアの技術発信・ポートフォリオサイト",
        subtitle: "20年の経験で培った技術知見とプロジェクト実績",
        cta_text: "お問い合わせ",
        cta_url: "#contact"
      }
      
      hero_section.section_contents.create!(
        content: hero_content,
        is_active: true,
        published_by: admin_user.id,
        published_at: Time.current
      )
      puts "✅ Hero section content created"
    end
    
    # Aboutセクションのサンプルコンテンツ
    about_section = Section.find_by(name: 'about')
    if about_section
      about_content = {
        title: "About Me",
        description: "20年間のソフトウェア開発経験を持つシニアエンジニア。要件定義からシステム設計、実装、運用まで幅広い経験を持ち、最近はAI/ML技術の活用にも注力しています。",
        image_url: "/images/profile.jpg"
      }
      
      about_section.section_contents.create!(
        content: about_content,
        is_active: true,
        published_by: admin_user.id,
        published_at: Time.current
      )
      puts "✅ About section content created"
    end
    
    # Serviceセクションのサンプルコンテンツ
    service_section = Section.find_by(name: 'service')
    if service_section
      service_content = {
        title: "Service",
        services: [
          {
            title: "要件定義・システム設計",
            description: "お客様の要望を具体的なシステム要件に落とし込み、最適なアーキテクチャを設計",
            icon: "clipboard-list"
          },
          {
            title: "フルスタック開発",
            description: "フロントエンドからバックエンド、インフラまで包括的な開発対応",
            icon: "code"
          },
          {
            title: "技術コンサルティング",
            description: "技術選定、アーキテクチャレビュー、開発プロセス改善の支援",
            icon: "light-bulb"
          }
        ]
      }
      
      service_section.section_contents.create!(
        content: service_content,
        is_active: true,
        published_by: admin_user.id,
        published_at: Time.current
      )
      puts "✅ Service section content created"
    end
    
    # Blogセクションのサンプルコンテンツ
    blog_section = Section.find_by(name: 'blog')
    if blog_section
      blog_content = {
        title: "Blog",
        description: "技術情報やプロジェクトの進捗、学んだことを発信しています",
        posts_count: 3
      }
      
      blog_section.section_contents.create!(
        content: blog_content,
        is_active: true,
        published_by: admin_user.id,
        published_at: Time.current
      )
      puts "✅ Blog section content created"
    end
    
    puts "🚀 Sample content creation completed!"
    puts "Total sections: #{Section.count}"
    puts "Total section contents: #{SectionContent.count}"
  end
end