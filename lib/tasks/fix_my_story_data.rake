namespace :my_story do
  desc "Fix timeline and skills_integration additional_data structure"
  task fix_data: :environment do
    puts "Starting My Story data fix..."

    # Fix Timeline Section
    timeline = MyStorySection.find_by(section_type: 'timeline')
    if timeline
      years = timeline.additional_data['years']
      if years.present?
        years.each do |year_data|
          if year_data['title'] == 'SE/PM・ビジネス分析者'
            year_data['description'] = '20年間、上流工程の専門家として大規模プロジェクトをリード'
            year_data['period'] = '2005-2025'
          end
        end
        timeline.additional_data['years'] = years
        timeline.save!
        puts "Fixed timeline section: #{timeline.title}"
      end
    else
      puts "Timeline section not found"
    end

    # Fix Skills Integration Section
    skills_section = MyStorySection.find_by(section_type: 'skills_integration')
    if skills_section
      # Convert old structure to new structure
      old_skills = skills_section.additional_data.dig('skills', 'list')
      
      if old_skills.present?
        # Convert from old format to new format
        skill_cards = old_skills.map do |skill|
          {
            'icon' => skill['icon'],
            'title' => skill['title'],
            'skills' => skill['items']
          }
        end
        
        skills_section.additional_data = {
          'skill_cards' => skill_cards,
          'summary' => skills_section.content
        }
        skills_section.save!
        puts "Fixed skills integration section: #{skills_section.title}"
      elsif skills_section.additional_data['skill_cards'].blank?
        # If no data exists, create default
        skills_section.additional_data = {
          'skill_cards' => [
            { 'icon' => '👨‍🏫', 'title' => '講師経験', 'skills' => ['人材育成・管理', '課題分析力', 'PM基礎力'] },
            { 'icon' => '🎯', 'title' => 'SE/PM経験', 'skills' => ['要件定義・業務分析', 'プロジェクト推進力', 'ステークホルダー調整'] },
            { 'icon' => '💻', 'title' => 'プログラミング', 'skills' => ['Ruby/Rails開発', 'Webアプリケーション構築', 'アーキテクチャ設計'] },
            { 'icon' => '🤖', 'title' => 'AI活用', 'skills' => ['ChatGPT API連携', 'AI効率化ツール開発', 'DXコンサルティング'] }
          ],
          'summary' => '「一人で要件定義から実装まで対応できる」という希少価値のあるエンジニアになることができました'
        }
        skills_section.save!
        puts "Created default skills integration data: #{skills_section.title}"
      else
        puts "Skills integration already has correct structure"
      end
    else
      puts "Skills integration section not found"
    end

    puts "Data fix completed!"
  end
end