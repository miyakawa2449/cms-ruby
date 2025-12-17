namespace :my_story do
  desc "Fix timeline and skills_integration additional_data structure (create if not exists)"
  task fix_data: :environment do
    puts "Starting My Story data fix..."

    # ========================================
    # Fix Timeline Section
    # ========================================
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
        puts "✓ Fixed timeline section: #{timeline.title}"
      end
    else
      puts "✗ Timeline section not found (create via admin or run db:seed)"
    end

    # ========================================
    # Fix or Create Skills Integration Section
    # ========================================
    skills_section = MyStorySection.find_by(section_type: 'skills_integration')
    
    skill_cards_data = {
      'skill_cards' => [
        { 'icon' => '👨‍🏫', 'title' => '講師経験', 'skills' => ['人材育成・管理', '課題分析力', 'PM基礎力'] },
        { 'icon' => '🎯', 'title' => 'SE/PM経験', 'skills' => ['要件定義・業務分析', 'プロジェクト推進力', 'ステークホルダー調整'] },
        { 'icon' => '💻', 'title' => 'プログラミング', 'skills' => ['Ruby/Rails開発', 'Webアプリケーション構築', 'アーキテクチャ設計'] },
        { 'icon' => '🤖', 'title' => 'AI活用', 'skills' => ['ChatGPT API連携', 'AI効率化ツール開発', 'DXコンサルティング'] }
      ],
      'summary' => '「一人で要件定義から実装まで対応できる」という希少価値のあるエンジニアになることができました'
    }
    
    if skills_section
      # レコードが存在する場合は更新
      old_skills = skills_section.additional_data.dig('skills', 'list')
      
      if old_skills.present?
        # 古い形式から変換
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
        puts "✓ Converted skills integration from old format"
      elsif skills_section.additional_data['skill_cards'].blank?
        # データが空の場合はデフォルトを設定
        skills_section.additional_data = skill_cards_data
        skills_section.save!
        puts "✓ Set default data for skills integration"
      else
        puts "✓ Skills integration already has correct structure"
      end
    else
      # レコードが存在しない場合は新規作成
      max_position = MyStorySection.maximum(:position) || 0
      
      skills_section = MyStorySection.create!(
        section_type: 'skills_integration',
        position: max_position + 1,
        title: 'まとめ: 統合されたスキルセット',
        subtitle: 'これらのスキルが組み合わさることで',
        content: '「一人で要件定義から実装まで対応できる」という希少価値のあるエンジニアになることができました',
        additional_data: skill_cards_data,
        is_active: true
      )
      puts "✓ Created skills integration section: #{skills_section.title}"
    end

    puts ""
    puts "Data fix completed!"
    puts "Please visit /my-story to verify the changes."
  end
end