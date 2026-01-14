# APIエンドポイントと既存機能の対応分析

## Step2: 既存機能とAPIエンドポイントの詳細マッピング

### 🔍 プロトタイプで特定したAPI化が必要な機能

#### 1. フロントエンド側のAPI利用箇所

##### A. 高度検索機能 (`blog_top_prototype.html`)

**現在の実装**
```javascript
// インクリメンタルサーチの仮実装
function performSearch(query) {
    // 現状: コンソールログのみ
    console.log('Searching for:', query);
}
```

**対応するAPIエンドポイント**
```
GET /api/v1/articles?search={query}&page=1&per_page=5
GET /api/v1/search/suggestions?q={query}      # サジェスト用
GET /api/v1/search/history                    # 検索履歴
```

**統合方法**
- リアルタイム検索（500ms遅延後にAPI呼び出し）
- 検索履歴はlocalStorage + APIで同期
- サジェスト機能で人気タグ・キーワード表示

##### B. ポートフォリオセクション (`portfolio_prototype.html`)

**現在の実装**
```html
<!-- 静的コンテンツとして実装 -->
<section id="about" class="section-spacing">
    <!-- プロフィール情報がハードコード -->
</section>
```

**対応するAPIエンドポイント**
```
GET /api/v1/portfolio                          # 全セクション取得
GET /api/v1/portfolio/works                    # 作品一覧
GET /api/v1/portfolio/works/{id}               # 作品詳細
```

**統合方法**
- 静的表示 → API経由の動的表示に変更
- セクション毎の公開/非公開制御
- コンテンツのリアルタイム更新

##### C. お問い合わせフォーム

**現在の実装**
```html
<!-- フォーム送信は未実装 -->
<form action="/contact" method="POST">
    <!-- 基本的なHTML form -->
</form>
```

**対応するAPIエンドポイント**
```
POST /api/v1/contacts                          # お問い合わせ送信
```

**統合方法**
- 非同期フォーム送信
- リアルタイムバリデーション
- reCAPTCHA統合
- 送信完了時の視覚的フィードバック

#### 2. 管理画面側のAPI利用箇所

##### A. 記事エディタ - AI機能 (`admin_article_editor_prototype.html`)

**現在の実装**
```html
<!-- AI分析結果は静的に表示 -->
<div class="ai-suggestion rounded-lg p-4">
    <p>SEO改善: 「Ruby on Rails OpenAI API 連携」などのキーワードを追加</p>
</div>
```

**対応するAPIエンドポイント**
```
POST /api/internal/ai/analyze                 # AI分析実行
GET  /api/internal/ai/analyze/{article_id}    # 分析結果取得
```

**統合方法**
- 記事保存時の自動AI分析
- リアルタイム進捗表示
- 分析結果の段階的表示
- 提案の選択的適用

##### B. メディアライブラリ

**現在の実装**
```html
<!-- 画像アップロードは基本的なHTML form -->
<input type="file" accept="image/*">
```

**対応するAPIエンドポイント**
```
POST /api/internal/media                      # メディアアップロード
GET  /api/internal/media                      # メディア一覧
PUT  /api/internal/media/{id}                 # メディア情報更新
```

**統合方法**
- ドラッグ&ドロップアップロード
- プログレスバー表示
- 自動WebP変換の進捗表示
- 使用状況のリアルタイム更新

##### C. 一括操作機能

**現在の実装**
```html
<!-- チェックボックスとボタン -->
<input type="checkbox" class="bulk-select">
<button onclick="bulkAction()">一括削除</button>
```

**対応するAPIエンドポイント**
```
PATCH /api/internal/articles/bulk             # 記事一括操作
DELETE /api/internal/articles/bulk            # 記事一括削除
```

**統合方法**
- 非同期一括処理
- 処理進捗の表示
- 失敗時の詳細エラー情報

### 🔄 既存機能との統合ポイント

#### 1. **段階的移行戦略**

**Phase 1: 既存機能の維持**
- 現在のHTML直接表示を維持
- APIエンドポイントを並行実装
- 管理画面でのAPI利用を先行

**Phase 2: フロントエンドAPI化**
- 検索機能のAPI化
- ポートフォリオの動的表示
- お問い合わせフォームのAPI化

**Phase 3: 完全API化**
- 全機能のAPI経由に移行
- キャッシング戦略の実装
- パフォーマンス最適化

#### 2. **データ整合性の保証**

**現在の設計との整合性**
```ruby
# 既存のArticleモデルがそのまま使用可能
class Api::V1::ArticlesController < Api::V1::BaseController
  def index
    # 既存のスコープとの互換性
    @articles = Article.published.includes(:categories, :tags)
    render json: @articles, meta: pagination_meta(@articles)
  end
end
```

**データベース設計との適合**
- 既存のテーブル構造を100%活用
- 追加のマイグレーションは不要
- APIトークン管理のみ新規追加検討

#### 3. **認証・認可の統合**

**管理画面認証との統合**
```ruby
# Deviseベースの認証をAPI用に拡張
class Api::Internal::BaseController < ApplicationController
  before_action :authenticate_user!  # 既存のDevise認証
  before_action :ensure_admin_role   # 既存のロール確認
end
```

**公開APIのセキュリティ**
```ruby
# レート制限の実装
class Api::V1::BaseController < ApplicationController
  include RateLimitable  # 新規実装が必要
end
```

### ⚠️ 実装時の考慮事項

#### 1. **パフォーマンスへの影響**

**キャッシング戦略**
- 記事一覧: 5分キャッシュ
- ポートフォリオ: 30分キャッシュ
- 検索結果: 1分キャッシュ

**N+1クエリの防止**
- 適切なincludes使用
- ページネーション実装
- レスポンスサイズの制限

#### 2. **SEOへの影響**

**サーバーサイドレンダリング維持**
- 重要ページ（トップ、記事詳細）は従来通りSSR
- 検索機能など補助的な機能をAPI化
- meta情報の動的生成維持

#### 3. **エラーハンドリング**

**ユーザー体験の向上**
- API障害時のフォールバック機能
- オフライン対応（Service Worker）
- エラー時の適切なメッセージ表示

### ✅ 統合完了時のメリット

#### 1. **開発効率の向上**
- フロントエンド・バックエンドの分離開発
- APIテストの自動化
- モックデータでの開発並行

#### 2. **将来拡張性**
- スマホアプリ開発への対応
- 外部サービス連携の簡易化
- マイクロサービス化への準備

#### 3. **運用の改善**
- リアルタイム機能の実装
- ユーザー体験の向上
- 管理作業の効率化

### 📋 Step2 完了確認

**✅ 確認済み項目**
- [x] 既存機能でのAPI利用箇所特定
- [x] APIエンドポイントとの1対1対応確認
- [x] データベース設計との完全整合性確認
- [x] 段階的移行戦略の策定
- [x] パフォーマンス・SEO影響の分析完了

**🎯 次のStep3での作業予定**
- spec.mdへの詳細API仕様追加
- 既存セクションとの統合方法明記
- 実装優先度の設定