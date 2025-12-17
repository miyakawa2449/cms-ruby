# My Story sections sample data
def create_my_story_sections
  puts "Creating My Story sections..."
  
  # Clear existing data
  MyStorySection.destroy_all
  
  # Hero Section
  hero_section = MyStorySection.create!(
    section_type: 'hero',
    position: 1,
    title: 'なぜ要件定義から実装まで<br><span class="text-yellow-300">一人でできる</span>のか？',
    subtitle: '宮川 剛のキャリアストーリー',
    content: 'パソコンスクール講師からSE/PM、そしてAIエンジニアへ。3つの転機がどのように組み合わさって、現在の独自のスキルセットを形成したかをご紹介します。',
    is_active: true
  )
  puts "Created hero section: #{hero_section.title}"

  # Timeline Section  
  timeline_section = MyStorySection.create!(
    section_type: 'timeline',
    position: 2,
    title: 'キャリアタイムライン',
    subtitle: '30年のキャリアで培った独自のスキルセット',
    content: '3つの時代を経て形成された、技術とビジネスを橋渡しする力',
    additional_data: {
      years: ['1994', '2005', '2022']
    },
    is_active: true
  )
  puts "Created timeline section: #{timeline_section.title}"

  # Chapter 1: パソコンスクール講師時代
  chapter1_section = MyStorySection.create!(
    section_type: 'chapter_1',
    position: 3,
    title: 'パソコンスクール講師時代',
    subtitle: '1994-2005年 | PM基礎力を培った11年間',
    content: '全国ネットのパソコンスクール講師として11年間、20人近い受講生を前に教室を運営。資格試験合格に向けた受講生の取りまとめを通じて、後のプロジェクト管理に欠かせないスキルの基礎を培いました。',
    additional_data: {
      skills: [
        '課題の明確化・分析',
        'モチベーション維持・管理', 
        'レベル差のある人材の統率',
        '資格試験指導・目標管理',
        '情報処理国家試験指導'
      ],
      achievements: [
        '全国ネット・パソコンスクール講師として11年間従事',
        '20人規模の教室運営・受講生管理',
        '情報処理国家試験・各種資格試験の指導実績',
        '受講生の合格率向上・モチベーション管理'
      ],
      quote: '20人近い受講生を前に教室を運営し、資格試験合格に向けて取りまとめる経験は、後のプロジェクト管理に大いに役立つスキルの基礎となった'
    },
    is_active: true
  )
  puts "Created chapter 1 section: #{chapter1_section.title}"

  # Chapter 2: SE/PM・ビジネス分析者時代
  chapter2_section = MyStorySection.create!(
    section_type: 'chapter_2',
    position: 4,
    title: 'SE/PM・ビジネス分析者時代',
    subtitle: '2005-2025年 | 上流工程専門家として20年間',
    content: 'SE/PMとして20年間、大規模プロジェクトの上流工程をリード。ビジネス分析者としてクライアントの本質的な課題を見極め、最適なソリューションを提案する力を磨きました。',
    additional_data: {
      skills: [
        'ビジネス要件の分析・文書化',
        '大規模プロジェクトの推進力',
        '多様なステークホルダーとの調整',
        'チームビルディング・リーダーシップ',
        '業務プロセスの最適化・提案'
      ],
      achievements: [
        '大規模プロジェクトの要件定義・設計',
        '多様なステークホルダーとの調整',
        '業務プロセスの最適化提案',
        '技術選定とアーキテクチャ設計',
        'DX・業務効率化による顧客価値創造'
      ],
      quote: '20年間のSE/PM経験で、ビジネス課題を技術で解決する力を徹底的に磨いた。この期間に培った上流工程のスキルが、現在の独自性の核となっている'
    },
    is_active: true
  )
  puts "Created chapter 2 section: #{chapter2_section.title}"

  # Chapter 3: AI活用エンジニア時代
  chapter3_section = MyStorySection.create!(
    section_type: 'chapter_3',
    position: 5,
    title: 'AI活用エンジニア時代',
    subtitle: '2022年-現在 | 全スキルの統合',
    content: 'AI登場を機にプログラミングを本格的に習得。講師時代の教育力、PM時代の課題解決力、そしてプログラミング技術が統合され、要件定義から実装まで一人で完結できる希少なスキルセットが完成しました。',
    additional_data: {
      skills: [
        'ChatGPT APIの活用方法習得',
        'Ruby/Rails でAI連携アプリ開発',
        'SE経験を活かした要件定義→実装',
        'AI効率化ツールの開発・提案',
        'DXコンサルティング・技術選定'
      ],
      achievements: [
        '講師経験 → 課題の明確化、わかりやすい説明',
        'PM経験 → 要件定義、ビジネス理解',
        'プログラミング → 実装力、技術選定',
        'AI活用 → 最新技術、効率化'
      ],
      quote: '30年のキャリアで積み重ねた3つのフェーズが、AI時代に最適な形で統合された。これこそが『一人でできる』理由である'
    },
    is_active: true
  )
  puts "Created chapter 3 section: #{chapter3_section.title}"

  # Skills Integration Section
  skills_section = MyStorySection.create!(
    section_type: 'skills_integration',
    position: 6,
    title: 'まとめ: 統合されたスキルセット',
    subtitle: 'これらのスキルが組み合わさることで',
    content: '「一人で要件定義から実装まで対応できる」という希少価値のあるエンジニアになることができました',
    additional_data: {
      skill_cards: [
        { 'icon' => '👨‍🏫', 'title' => '講師経験', 'skills' => ['人材育成・管理', '課題分析力', 'PM基礎力'] },
        { 'icon' => '🎯', 'title' => 'SE/PM経験', 'skills' => ['要件定義・業務分析', 'プロジェクト推進力', 'ステークホルダー調整'] },
        { 'icon' => '💻', 'title' => 'プログラミング', 'skills' => ['Ruby/Rails開発', 'Webアプリケーション構築', 'アーキテクチャ設計'] },
        { 'icon' => '🤖', 'title' => 'AI活用', 'skills' => ['ChatGPT API連携', 'AI効率化ツール開発', 'DXコンサルティング'] }
      ],
      summary: '「一人で要件定義から実装まで対応できる」という希少価値のあるエンジニアになることができました'
    },
    is_active: true
  )
  puts "Created skills integration section: #{skills_section.title}"

  # Projects Section
  projects_section = MyStorySection.create!(
    section_type: 'projects',
    position: 7,
    title: '実績・事例',
    subtitle: '統合されたスキルセットによる実績',
    content: '要件定義から実装まで一貫した対応により、様々なプロジェクトを成功に導いています',
    additional_data: {
      items: [
        {
          title: '要件定義〜システム構築',
          description: 'お客様のビジネス課題を分析し、最適なシステムを一貫して構築',
          period: '6ヶ月',
          scale: '中規模',
          technologies: ['Ruby/Rails', 'PostgreSQL', 'Docker', 'AWS']
        },
        {
          title: 'レガシーシステム モダン化',
          description: '古いシステムを現代的な技術スタックで再構築',
          period: '8ヶ月',
          scale: '大規模', 
          technologies: ['Python', 'Docker', 'AWS', 'Microservices']
        },
        {
          title: 'AI活用ツール開発',
          description: 'ChatGPT APIを活用した業務効率化ツールの開発',
          period: '3ヶ月',
          scale: '小規模',
          technologies: ['ChatGPT API', 'React', 'Node.js', 'TypeScript']
        }
      ]
    },
    is_active: true
  )
  puts "Created projects section: #{projects_section.title}"

  # CTA Section
  cta_section = MyStorySection.create!(
    section_type: 'cta',
    position: 8,
    title: 'あなたのプロジェクトにお役に立てますか？',
    subtitle: '上流から下流まで一貫したサポートでプロジェクト成功をお手伝いします',
    content: '要件定義から実装まで一貫した対応により、プロジェクト成功を実現します',
    additional_data: {
      buttons: [
        {
          text: 'ポートフォリオを見る',
          url: '/',
          style: 'primary'
        },
        {
          text: 'お問い合わせ',
          url: '#contact',
          style: 'secondary'
        }
      ]
    },
    is_active: true
  )
  puts "Created CTA section: #{cta_section.title}"

  puts "✓ Successfully created #{MyStorySection.count} My Story sections"
end

# Execute if called directly
create_my_story_sections if __FILE__ == $0