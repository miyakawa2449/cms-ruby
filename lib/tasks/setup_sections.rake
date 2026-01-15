namespace :portfolio do
  desc "Setup all 8 sections for portfolio site"
  task setup_sections: :environment do
    sections_data = [
      { name: "about", display_name: "About", position: 2, is_visible: true },
      { name: "service", display_name: "Service", position: 3, is_visible: true },
      { name: "my_story", display_name: "My Story", position: 4, is_visible: true },
      { name: "works", display_name: "Works", position: 5, is_visible: true },
      { name: "blog", display_name: "Blog", position: 6, is_visible: true },
      { name: "contact", display_name: "Contact", position: 7, is_visible: true },
      { name: "footer", display_name: "Footer", position: 8, is_visible: true }
    ]

    sections_data.each do |data|
      section = Section.find_or_create_by(name: data[:name]) do |s|
        s.display_name = data[:display_name]
        s.position = data[:position]
        s.is_visible = data[:is_visible]
      end

      puts "✅ Section created: #{section.name} - #{section.display_name}"
    end

    puts "🚀 Total sections: #{Section.count}"
  end
end
