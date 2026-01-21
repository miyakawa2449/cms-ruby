# Claude Code 指示書: My Story ページの修正

## 概要
My Storyページの5つの問題を修正：
1. キャリアタイムラインの年数表記修正（16年→20年、2021→2025）
2. 「まとめ：統合されたスキルセット」セクションが表示されない問題
3. 「お問い合わせ」リンク先の修正
4. 「実績・事例」エリアをトップページWorksセクションと同じ表示に
5. ページ下部の重複した「ポートフォリオに戻る」を削除

---

## 修正1: タイムラインの年数修正

**ファイル**: `db/seeds/my_story_data.rb`

タイムラインセクションの SE/PM・ビジネス分析者の項目を修正：

```diff
- { 'year' => '2005', 'title' => 'SE/PM・ビジネス分析者', 'description' => '16年間、上流工程の専門家として大規模プロジェクトをリード', 'skills' => 'ビジネス理解力・プロジェクト推進力', 'period' => '2005-2021', 'color' => 'blue' },
+ { 'year' => '2005', 'title' => 'SE/PM・ビジネス分析者', 'description' => '20年間、上流工程の専門家として大規模プロジェクトをリード', 'skills' => 'ビジネス理解力・プロジェクト推進力', 'period' => '2005-2025', 'color' => 'blue' },
```

---

## 修正2: skills_integration セクションの additional_data 構造修正

**ファイル**: `db/seeds/my_story_data.rb`

skills_integrationセクションの `additional_data` を修正：

### 修正前:
```ruby
additional_data: {
  skills: {
    list: [
      { icon: '👨‍🏫', title: '講師経験', items: [...] },
      ...
    ]
  }
},
```

### 修正後:
```ruby
additional_data: {
  skill_cards: [
    { 'icon' => '👨‍🏫', 'title' => '講師経験', 'skills' => ['人材育成・管理', '課題分析力', 'PM基礎力'] },
    { 'icon' => '🎯', 'title' => 'SE/PM経験', 'skills' => ['要件定義・業務分析', 'プロジェクト推進力', 'ステークホルダー調整'] },
    { 'icon' => '💻', 'title' => 'プログラミング', 'skills' => ['Ruby/Rails開発', 'Webアプリケーション構築', 'アーキテクチャ設計'] },
    { 'icon' => '🤖', 'title' => 'AI活用', 'skills' => ['ChatGPT API連携', 'AI効率化ツール開発', 'DXコンサルティング'] }
  ],
  summary: '「一人で要件定義から実装まで対応できる」という希少価値のあるエンジニアになることができました'
},
```

---

## 修正3: お問い合わせリンク先の修正

**ファイル**: `app/views/my_story/index.html.erb`

261行目付近を修正：

```diff
- <a href="#contact" class="inline-block border-2 border-blue-900 text-blue-900 px-8 py-3 rounded-lg font-semibold hover:bg-blue-900 hover:text-white transition-colors">
+ <a href="https://example.test/#contact" class="inline-block border-2 border-blue-900 text-blue-900 px-8 py-3 rounded-lg font-semibold hover:bg-blue-900 hover:text-white transition-colors">
    お問い合わせ
  </a>
```

---

## 修正4: 実績・事例エリアをWorksセクションと同じ表示に

**ファイル**: `app/views/my_story/index.html.erb`

164行目〜222行目付近の `<% elsif section.projects_section? %>` ブロック全体を以下に置き換え：

```erb
    <% elsif section.projects_section? %>
      <!-- Projects Section - Render Works partial -->
      <%= render 'portfolio/sections/works' %>
```

### 削除するコード（164行目〜222行目付近）:
```erb
    <% elsif section.projects_section? %>
      <!-- Projects Section (positioned dynamically) -->
      <section class="py-20 bg-gray-50">
        <div class="container mx-auto px-6">
          <div class="text-center mb-16">
            <h2 class="text-3xl font-bold mb-6"><%= section.title %></h2>
          </div>
          
          <div class="grid md:grid-cols-3 gap-8 max-w-6xl mx-auto">
            <% @recent_works.limit(3).each do |work| %>
              ... (省略)
            <% end %>
          </div>
          
          <div class="text-center mt-8">
            <%= link_to "/blog?category=works", 
                        class: "bg-blue-600 text-white font-semibold py-3 px-8 rounded-lg hover:bg-blue-700 transition-colors" do %>
              詳細な事例を見る
            <% end %>
          </div>
        </div>
      </section>
```

---

## 修正5: 重複した「ポートフォリオに戻る」を削除

**ファイル**: `app/views/my_story/index.html.erb`

269行目〜276行目の白背景エリアを削除：

```diff
- <!-- Navigation -->
- <div class="bg-white py-6 border-t border-gray-200">
-   <div class="container mx-auto px-6 text-center">
-     <%= link_to root_path, class: "text-blue-600 hover:text-blue-700 font-medium" do %>
-       ← ポートフォリオに戻る
-     <% end %>
-   </div>
- </div>
```

---

## 修正6: 既存データ更新用Rakeタスク作成

**ファイル**: `lib/tasks/fix_my_story_data.rake`（新規作成）

```ruby
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
```

---

## デプロイ手順

### 1. コード修正をコミット・プッシュ
```bash
git add -A
git commit -m "Fix My Story page: timeline, skills_integration, contact link, works section, duplicate nav"
git push origin main
```

### 2. サーバーでデプロイ実行
```bash
cd /path/to/project
git pull origin main
./scripts/deploy.sh --keep-ssl --recreate
```

### 3. データ修正Rakeタスク実行
```bash
docker compose -f docker-compose.production.yml exec portfolio-web rails my_story:fix_data
```

---

## 動作確認

1. `/my-story` にアクセス

2. **キャリアタイムライン**を確認：
   - 「20年間、上流工程の専門家として〜」と表示されること
   - 「2005-2025」と表示されること

3. **「まとめ：統合されたスキルセット」セクション**を確認：
   - 4つのスキルカード（講師経験、SE/PM経験、プログラミング、AI活用）が表示されること
   - まとめ文が表示されること

4. **実績・事例エリア**を確認：
   - トップページと同じWorksセクションが表示されること
   - GitHub/デモリンク、「詳細を見る」リンクがあること

5. **「お問い合わせ」リンク**をクリック：
   - `https://example.test/#contact` に遷移すること

6. **ページ下部**を確認：
   - 白背景の「ポートフォリオに戻る」が削除され、重複がないこと

---

## 修正ファイル一覧

| ファイル | 操作 |
|---------|------|
| `db/seeds/my_story_data.rb` | 修正（2箇所） |
| `app/views/my_story/index.html.erb` | 修正（3箇所） |
| `lib/tasks/fix_my_story_data.rake` | **新規作成** |
