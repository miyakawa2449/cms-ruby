# Claude Code 指示書: My Story 管理画面修正 & Contact Session 修正

## 概要
ポートフォリオサイトの2つの問題を修正する指示書です。

---

## タスク1: Contact Session のレスポンス時間修正

### 対象ファイル
`app/views/portfolio/sections/_contact.html.erb`

### 修正内容
120行目付近のレスポンス時間の文言を変更：

```diff
- <p class="text-gray-300">通常24時間以内にご返信します</p>
+ <p class="text-gray-300">3営業日以内にご返信いたします</p>
```

---

## タスク2: My Story 管理画面の章フィールド保存機能修正

### 問題
管理画面で第1〜3章（chapter_1, chapter_2, chapter_3）の「習得したスキル」「主な実績」「章の引用文」フィールドに入力しても、`additional_data` JSONBカラムに正しく保存されない。

### 修正ファイル一覧

1. `app/models/my_story_section.rb`
2. `app/controllers/admin/my_story_sections_controller.rb`
3. `db/seeds/my_story_data.rb`
4. `db/seeds/create_my_story_sections.rb`

---

### 修正1: モデルに仮想属性とコールバックを追加

**ファイル**: `app/models/my_story_section.rb`

#### Step 1: 仮想属性を追加
`SECTION_TYPE_LABELS` 定数の後、`has_one_attached` の前に追加：

```ruby
# Virtual attributes for form input (chapter sections)
attr_accessor :skills, :achievements, :quote
```

#### Step 2: コールバックを追加
`before_validation :set_default_position, if: :new_record?` の後に追加：

```ruby
before_save :sync_chapter_fields_to_additional_data
after_initialize :load_chapter_fields_from_additional_data
```

#### Step 3: プライベートメソッドを追加
`set_default_position` メソッドの後に追加：

```ruby
# Load virtual attributes from additional_data when record is loaded
def load_chapter_fields_from_additional_data
  return unless chapter_section?
  
  @skills = chapter_skills.join("\n") if chapter_skills.any?
  @achievements = chapter_achievements.join("\n") if chapter_achievements.any?
  @quote = chapter_quote
end

# Sync virtual attributes to additional_data before save
def sync_chapter_fields_to_additional_data
  return unless chapter_section?
  
  self.additional_data ||= {}
  
  # Parse skills from textarea (newline-separated)
  if @skills.present?
    self.additional_data['skills'] = @skills.to_s.split(/[\r\n]+/).map(&:strip).reject(&:blank?)
  end
  
  # Parse achievements from textarea (newline-separated)
  if @achievements.present?
    self.additional_data['achievements'] = @achievements.to_s.split(/[\r\n]+/).map(&:strip).reject(&:blank?)
  end
  
  # Set quote directly
  if @quote.present?
    self.additional_data['quote'] = @quote.to_s.strip
  end
end
```

---

### 修正2: コントローラーのストロングパラメータ更新

**ファイル**: `app/controllers/admin/my_story_sections_controller.rb`

`my_story_section_params` メソッド内の `permit` に以下を追加：

```ruby
def my_story_section_params
  params.require(:my_story_section).permit(
    :section_type,
    :title, 
    :subtitle,
    :content,
    :position,
    :is_active,
    :background_image,
    :chapter_image,
    :skills,        # 追加
    :achievements,  # 追加
    :quote,         # 追加
    gallery_images: [],
    # ... 以下省略
  )
end
```

---

### 修正3: シードデータの additional_data 構造修正

**重要**: `additional_data` の構造を `MyStorySectionJsonManager` と一致させる必要がある。

#### 変更前（ネスト構造）:
```ruby
additional_data: {
  chapter: {
    skills: [...],
    achievements: [...],
    quote: "..."
  }
}
```

#### 変更後（フラット構造）:
```ruby
additional_data: {
  skills: [...],
  achievements: [...],
  quote: "..."
}
```

#### Timeline セクションも同様:

変更前:
```ruby
additional_data: {
  timeline: {
    years: [...]
  }
}
```

変更後:
```ruby
additional_data: {
  years: [...]
}
```

---

## 動作確認手順

1. 管理画面 `/admin/my_story_sections` にアクセス
2. 第1章〜第3章のいずれかを編集
3. 「習得したスキル」「主な実績」「章の引用文」に値を入力して保存
4. 再度編集画面を開き、入力した値が表示されることを確認
5. フロントエンド `/my-story` で入力した内容が表示されることを確認

---

## 補足: MyStorySectionJsonManager の仕様

`app/services/my_story_section_json_manager.rb` は以下の構造で `additional_data` を読み書きする：

| メソッド | キー |
|---------|------|
| `chapter_skills` | `additional_data['skills']` |
| `chapter_achievements` | `additional_data['achievements']` |
| `chapter_quote` | `additional_data['quote']` |
| `timeline_years` | `additional_data['years']` |

フォームからの入力はこの構造に合わせて保存する必要がある。
