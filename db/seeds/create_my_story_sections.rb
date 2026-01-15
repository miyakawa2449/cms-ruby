# My Story sections seed data

# Hero section
MyStorySection.create!(
  section_type: 'hero',
  title: 'なぜ要件定義から実装まで<br><span class="text-yellow-300">一人でできる</span>のか？',
  subtitle: '宮川 剛のキャリアストーリー',
  content: 'パソコンスクール講師からSE/PM、そしてAIエンジニアへ。3つの転機がどのように組み合わさって、現在の独自のスキルセットを形成したかをご紹介します。',
  position: 1,
  is_active: true
)

# Timeline section
MyStorySection.create!(
  section_type: 'timeline',
  title: 'キャリアタイムライン',
  content: '30年のキャリアで培った独自のスキルセット',
  position: 2,
  is_active: true,
  additional_data: {
    years: [
      { year: 1994, title: 'パソコンスクール講師', description: '20人近い受講生を取りまとめ、PM基礎力を形成', skill: '人材育成・プロジェクト管理基礎', period: '1994-2005' },
      { year: 2005, title: 'SE/PM・ビジネス分析者', description: '16年間、上流工程の専門家として大規模プロジェクトをリード', skill: 'ビジネス理解力・プロジェクト推進力', period: '2005-2021' },
      { year: 2022, title: 'AI活用エンジニア', description: 'AI登場を機にプログラミングを習得、全スキルを統合', skill: 'AI × プログラミング × PM経験', period: '2022-現在' }
    ]
  }
)

# Chapter 1
MyStorySection.create!(
  section_type: 'chapter_1',
  title: '第1章: パソコンスクール講師時代',
  subtitle: '1994-2005年 | PM基礎力を培った11年間',
  content: '全国ネットのパソコンスクール講師として11年間、20人近い受講生を前に教室を運営。資格試験合格に向けた受講生の取りまとめを通じて、後のプロジェクト管理に欠かせないスキルの基礎を培いました。',
  position: 3,
  is_active: true,
  additional_data: {
    skills: [ '課題の明確化・分析', 'モチベーション維持・管理', 'レベル差のある人材の統率', '資格試験指導・目標管理', '情報処理国家試験指導' ],
    achievements: [ '教室運営で培った人材管理・課題解決スキルは、後のプロジェクト管理業務の強固な基盤となりました。' ],
    quote: '20人近い受講生を前に教室を運営し、資格試験合格に向けて取りまとめる経験は、後のプロジェクト管理に大いに役立つスキルの基礎となった...'
  }
)

puts 'My Story sections created successfully!'
