# Claude Code 指示書: My Story 新規セクション追加時の500エラー修正

## 問題
管理画面 `/admin/my_story_sections` で「新規セクション追加」をクリックすると500エラーが発生する。

## 原因
`app/models/my_story_section.rb` の `load_chapter_fields_from_additional_data` メソッドで、`section_type` が `nil`（新規作成時）の状態で `chapter_section?` を呼んでいる。`chapter_section?` 内部の `start_with?` メソッドが `nil` に対して呼ばれてエラーになる。

## 修正箇所

**ファイル**: `app/models/my_story_section.rb`

### 修正1: `load_chapter_fields_from_additional_data` メソッド

```diff
  def load_chapter_fields_from_additional_data
-   return unless chapter_section?
+   return unless section_type.present? && chapter_section?
    
    @skills = chapter_skills.join("\n") if chapter_skills.any?
    @achievements = chapter_achievements.join("\n") if chapter_achievements.any?
    @quote = chapter_quote
  end
```

### 修正2: `sync_chapter_fields_to_additional_data` メソッド（念のため）

```diff
  def sync_chapter_fields_to_additional_data
-   return unless chapter_section?
+   return unless section_type.present? && chapter_section?
    
    self.additional_data ||= {}
    # ... 以下同じ
  end
```

## デプロイ

```bash
./scripts/deploy.sh --keep-ssl --recreate
```

## 動作確認
1. `/admin/my_story_sections` にアクセス
2. 「新規セクション追加」をクリック → 500エラーが出ないこと
