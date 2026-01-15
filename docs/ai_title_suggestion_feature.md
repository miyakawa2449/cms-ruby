# AI タイトル提案機能

## 概要

記事編集画面で、AIが記事本文の内容を分析して、2種類のタイトルを提案する機能です。

### 提案されるタイトルの種類

1. **わかりやすいタイトル（Descriptive）**
   - 記事の内容を正確に表現
   - 読者が内容を理解しやすい
   - 検索エンジンに最適化（SEO重視）
   - 30〜50文字程度

2. **SNS映えするタイトル（Engaging）**
   - クリックされやすい魅力的な表現
   - 好奇心を刺激する
   - 感情に訴える
   - 数字や具体例を含む
   - 25〜40文字程度

## 使い方

1. 記事を作成・保存する（本文を入力）
2. タイトルフィールドの横にある「AI提案」ボタンをクリック
3. 2種類のタイトル候補（各3個ずつ）が表示される
4. 気に入ったタイトルをクリックして適用

## 実装詳細

### バックエンド

#### サービスクラス
- `app/services/ai/title_suggester.rb`
  - AWS Bedrockを使用してタイトルを生成
  - 記事本文（最大2000文字）を分析
  - 2種類のタイトルを各3個ずつ生成

#### コントローラー
- `app/controllers/admin/ai_controller.rb`
  - `suggest_title` アクション追加
  - エンドポイント: `POST /admin/articles/:article_id/ai/suggest_title`

#### ルーティング
```ruby
namespace :ai do
  post 'suggest_title', action: :suggest_title, controller: '/admin/ai'
end
```

### フロントエンド

#### Stimulus コントローラー
- `app/javascript/controllers/ai_assistant_controller.js`
  - `suggestTitle()` メソッド追加
  - `displayTitleResults()` メソッド追加
  - `applyTitle()` メソッド追加

#### ビュー
- `app/views/admin/articles/_form.html.erb`
  - タイトルフィールドに「AI提案」ボタン追加
  - 提案結果表示エリア追加

### データフロー

```
1. ユーザーが「AI提案」ボタンをクリック
   ↓
2. JavaScript が API リクエスト送信
   POST /admin/articles/:id/ai/suggest_title
   ↓
3. Ai::TitleSuggester が記事本文を分析
   ↓
4. AWS Bedrock API にプロンプト送信
   ↓
5. AI が2種類のタイトルを生成
   ↓
6. JSON レスポンスを返却
   {
     "success": true,
     "data": {
       "descriptive_titles": [...],
       "engaging_titles": [...]
     }
   }
   ↓
7. JavaScript が結果を表示
   ↓
8. ユーザーがタイトルを選択して適用
```

## API レスポンス例

```json
{
  "success": true,
  "data": {
    "descriptive_titles": [
      {
        "title": "Rails 7でAI機能を実装する完全ガイド",
        "reason": "記事の内容を正確に表現し、検索エンジンに最適化"
      },
      {
        "title": "AWS BedrockとRailsで作るAI搭載CMS",
        "reason": "技術スタックを明示し、ターゲット読者を明確化"
      }
    ],
    "engaging_titles": [
      {
        "title": "【実装例付き】Rails開発者が知るべきAI活用術",
        "reason": "実装例という具体性で好奇心を刺激"
      },
      {
        "title": "たった3ステップでRailsアプリにAI機能を追加する方法",
        "reason": "数字を使って簡単さをアピール"
      }
    ],
    "current_title": "既存のタイトル"
  },
  "metadata": {
    "article_id": 123,
    "content_length": 5000,
    "generated_at": "2026-01-15T10:30:00Z"
  }
}
```

## テスト

### RSpec テスト
- `spec/services/ai/title_suggester_spec.rb` - サービスクラスのテスト
- `spec/requests/admin/ai_controller_spec.rb` - コントローラーのテスト

### テスト実行
```bash
# 全テスト実行
bundle exec rspec spec/services/ai/title_suggester_spec.rb
bundle exec rspec spec/requests/admin/ai_controller_spec.rb

# 特定のテストのみ実行
bundle exec rspec spec/services/ai/title_suggester_spec.rb:10
```

## UI/UX

### デザイン
- わかりやすいタイトル: 青色のアクセント（`bg-blue-50`）
- SNS映えするタイトル: 紫色のアクセント（`bg-purple-50`）
- ホバー時に境界線が表示され、クリック可能であることを示す
- 選択理由も表示され、ユーザーが判断しやすい

### アニメーション
- タイトル適用時にフィールドが緑色にハイライト（2秒間）
- ローディング中は「タイトルを提案中...」と表示

## 注意事項

1. **記事保存が必要**: AI機能を使用するには、まず記事を保存する必要があります
2. **本文が必要**: タイトル提案には記事本文が必要です（空の場合はエラー）
3. **AWS設定**: AWS Bedrock の認証情報が必要です
4. **文字数制限**: 本文の最初の2000文字のみを分析対象とします

## 今後の拡張案

- [ ] タイトルの文字数カウント表示
- [ ] タイトルのSEOスコア表示
- [ ] ユーザーフィードバック機能（良い/悪い）
- [ ] 提案履歴の保存
- [ ] カスタムプロンプトの設定
- [ ] 多言語対応

## 関連機能

- AI要約機能（`Ai::SummaryGenerator`）
- AIタグ提案機能（`Ai::TagSuggester`）
- AIスラッグ生成機能（`Ai::SlugGenerator`）
- AI SEOメタ生成機能（`Ai::SeoMetaGenerator`）
