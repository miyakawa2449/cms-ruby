# ポートフォリオ・ブログサイト

シニアエンジニアの技術発信・ポートフォリオサイト（CMS機能付き）

## 📋 概要

要件定義からプログラミングまで一貫して対応できるシニアエンジニアの技術発信サイトです。
縦スクロール型のポートフォリオページと、本格的な技術ブログ機能を搭載しています。

### 主な特徴
- 🎨 **セクション管理型CMS** - ポートフォリオの各セクションを個別管理
- 📝 **Markdownブログ** - 技術記事の執筆に最適化・AIアシスト機能付き
- 🔍 **高度検索機能** - インクリメンタルサーチ・履歴・サジェスト対応
- 🤖 **AI統合システム** - GPT-4による記事要約・SEO最適化・コンテンツ提案
- 📊 **運用監視ダッシュボード** - システム稼働状況・パフォーマンス・エラー監視
- 🔒 **企業レベルセキュリティ** - 2FA・IP制限・管理画面パス変更
- 💬 **リアルタイム通知** - Slack統合・複数チャンネル対応
- 🔧 **自動バックアップ** - 日次/週次スケジュール・復元機能
- 🔎 **SEO完全対応** - 構造化データ・sitemap・robots.txt管理
- 📱 **完全レスポンシブ** - モバイルファースト・タッチ最適化

## 🛠 技術スタック

### Backend
- **Ruby** 3.4.0
- **Ruby on Rails** 8.0.1
- **PostgreSQL** - メインデータベース
- **Sidekiq** - バックグラウンドジョブ（AI処理）

### Frontend
- **Tailwind CSS** - ユーティリティファースト
- **JavaScript** - インタラクション・検索
- **Turbo** - SPA風エクスペリエンス

### Infrastructure
- **Docker** - 開発環境
- **AWS Lightsail** - 本番環境
- **Nginx** - Webサーバー

### External Services
- **OpenAI API (GPT-4)** - 記事要約・SEO最適化・コンテンツ生成
- **Slack API & Webhooks** - リアルタイム通知・複数チャンネル対応
- **Google Analytics** - アクセス解析・SEOパフォーマンス追跡
- **AWS S3** - メディアファイル・バックアップストレージ

### AI機能の差別化ポイント
- **インテリジェントSEO**: AI駆動の自動メタデータ生成・キーワード最適化
- **コンテンツ品質向上**: GPT-4による記事要約・改善提案
- **運用効率化**: 自動カテゴリ提案・関連記事マッチング
- **パフォーマンス監視**: AI分析によるSEOスコア・読了時間予測

## 📁 プロジェクト構成

```
portfolio_rb/
├── README.md
├── CLAUDE.md                          # プロジェクトメモリ（Claude Code用）
├── Gemfile
├── Gemfile.lock
├── Dockerfile
├── docker-compose.yml
├── config/
│   ├── application.rb
│   ├── routes.rb
│   ├── database.yml
│   └── environments/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── home_controller.rb          # ポートフォリオページ
│   │   ├── blog_controller.rb          # ブログ機能
│   │   ├── search_controller.rb        # 検索機能
│   │   └── admin/                      # 管理画面
│   │       ├── dashboard_controller.rb
│   │       ├── articles_controller.rb
│   │       ├── sections_controller.rb  # ポートフォリオセクション
│   │       ├── media_controller.rb     # メディアライブラリ
│   │       └── settings_controller.rb  # システム設定
│   ├── models/
│   │   ├── article.rb                  # ブログ記事
│   │   ├── category.rb                 # カテゴリ（階層対応）
│   │   ├── tag.rb                      # タグ
│   │   ├── section.rb                  # ポートフォリオセクション
│   │   ├── media_file.rb               # メディアファイル
│   │   └── user.rb                     # 管理ユーザー
│   ├── services/
│   │   ├── openai_service.rb           # GPT API連携
│   │   ├── search_service.rb           # 検索処理
│   │   ├── image_processor_service.rb  # 画像処理
│   │   └── seo_service.rb              # SEO最適化
│   ├── jobs/
│   │   ├── article_ai_processor_job.rb # AI処理（非同期）
│   │   └── image_optimizer_job.rb      # 画像最適化
│   ├── views/
│   │   ├── layouts/
│   │   │   ├── application.html.erb
│   │   │   └── admin.html.erb
│   │   ├── home/
│   │   │   ├── index.html.erb          # ポートフォリオページ
│   │   │   └── my_story.html.erb       # My Storyページ
│   │   ├── blog/
│   │   │   ├── index.html.erb          # 記事一覧
│   │   │   ├── show.html.erb           # 記事詳細
│   │   │   └── category.html.erb       # カテゴリ別一覧
│   │   └── admin/                      # 管理画面テンプレート
│   └── assets/
│       ├── stylesheets/
│       │   └── application.tailwind.css
│       └── javascripts/
│           ├── application.js
│           └── admin.js
├── db/
│   ├── migrate/
│   └── seeds.rb
├── docs/
│   ├── specifications/
│   │   └── spec.md                     # 詳細仕様書
│   ├── wireframes/                     # 画面設計プロトタイプ（16画面）
│   │   ├── portfolio_prototype.html    # ポートフォリオトップ
│   │   ├── my_story_prototype.html     # My Storyページ
│   │   ├── blog_top_prototype.html     # ブログトップ（高度検索付き）
│   │   ├── blog_article_prototype.html # 記事詳細
│   │   ├── blog_category_prototype.html # カテゴリページ
│   │   └── app/views/admin/            # 管理画面プロトタイプ
│   │       ├── admin_dashboard_prototype.html         # ダッシュボード
│   │       ├── admin_blog_prototype.html             # 記事管理
│   │       ├── admin_article_editor_prototype.html   # 記事エディタ（AI機能）
│   │       ├── admin_categories_prototype.html       # カテゴリ管理
│   │       ├── admin_category_create_prototype.html  # カテゴリ作成
│   │       ├── admin_users_prototype.html            # ユーザー管理
│   │       ├── admin_comments_prototype.html         # コメント管理
│   │       ├── admin_media_prototype.html            # メディアライブラリ
│   │       ├── admin_portfolio_prototype.html        # ポートフォリオCMS
│   │       └── admin_settings_prototype.html         # 設定（8タブ構成）
│   ├── analysis/                       # 仕様分析ドキュメント
│   │   ├── spec_features.md            # spec.md機能一覧
│   │   ├── prototype_features.md       # プロトタイプ機能分析
│   │   └── gap_analysis.md            # 差分分析結果
│   └── api/                            # API仕様
└── spec/                               # テスト
    ├── models/
    ├── controllers/
    ├── services/
    └── factories/
```

## 🎯 サイト構成

### フロントエンド
```
/                                       # ポートフォリオ（トップページ）
├── ヘッダー・ナビゲーション
├── ヒーローセクション
├── Aboutセクション
├── Serviceセクション  
├── My Storyセクション
├── Worksセクション
├── Blogセクション
├── Contactセクション（Slack連携）
└── フッター

/my-story                               # My Story詳細ページ
/blog                                   # ブログトップ
/blog/{slug}                           # 記事詳細
/blog/category/{slug}                  # カテゴリ別一覧
/blog/tag/{slug}                       # タグ別一覧
```

### 管理画面（16画面完備）
```
/{admin_path}                          # ダッシュボード（パス変更可能）
├── /dashboard                         # 統計・KPI・クイックアクション
├── /articles                          # ブログ記事管理（一括操作・AI機能）
│   ├── /new                          # 記事作成エディタ（AI要約・SEO提案）
│   └── /edit/:id                     # 記事編集（リアルタイムプレビュー）
├── /categories                        # カテゴリ管理（2階層・ドラッグ&ドロップ）
│   └── /new                          # カテゴリ作成（色・アイコン設定）
├── /comments                          # コメント管理（承認・スパム検知）
├── /media                             # メディアライブラリ（WebP変換・使用状況）
├── /portfolio                         # ポートフォリオCMS（8セクション）
├── /users                             # ユーザー管理（ロール・権限）
├── /analytics                         # アクセス解析（GA連携・レポート）
└── /settings                          # システム設定（8タブ構成）
    ├── /general                       # 一般設定・メンテナンスモード
    ├── /seo                          # SEO設定・構造化データ・sitemap・robots.txt
    ├── /ai                           # AI連携・OpenAI設定・機能制御
    ├── /security                     # セキュリティ・2FA・IP制限
    ├── /integrations                 # 外部連携・Slack・SNS API
    ├── /email                        # メール設定・SMTP
    ├── /backup                       # バックアップ・復元・ストレージ管理
    └── /monitoring                   # 監視・運用・パフォーマンス・エラー監視
```

## 🚀 セットアップ

### 必要な環境
- Ruby 3.4.0+
- PostgreSQL 14+
- Docker Desktop（推奨）
- **OpenAI API Key** - AI機能利用に必須
- **Slack Webhook URL** - リアルタイム通知機能（オプション）
- **Google Analytics ID** - アクセス解析（オプション）

### 開発環境構築

1. **リポジトリクローン**
   ```bash
   git clone [repository-url]
   cd portfolio_rb
   ```

2. **Docker環境での起動**
   ```bash
   docker-compose up -d
   ```

3. **データベース初期化**
   ```bash
   docker-compose exec app rails db:create
   docker-compose exec app rails db:migrate
   docker-compose exec app rails db:seed
   ```

4. **環境変数設定**
   ```bash
   cp .env.example .env
   ```
   
   `.env`ファイルに以下の設定を追加：
   ```bash
   # 🤖 OpenAI API設定（AI機能に必須）
   OPENAI_API_KEY=sk-your-openai-api-key-here
   OPENAI_MODEL=gpt-4-turbo-preview
   OPENAI_MONTHLY_BUDGET=50
   
   # 💬 Slack連携設定（オプション）
   SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
   SLACK_CHANNEL=#general
   
   # 📊 Analytics設定（オプション）
   GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
   
   # 🔒 セキュリティ設定
   ADMIN_PATH=admin
   SECRET_KEY_BASE=generate-with-rails-secret
   
   # 🗄️ データベース設定
   DATABASE_URL=postgresql://user:pass@localhost:5432/portfolio_rb_development
   ```

### 本番環境デプロイ

詳細は `docs/deployment.md` を参照

## 📖 使用方法

### 管理画面アクセス
1. `http://localhost:3000/admin` （デフォルト）
2. 初期ユーザー: `admin@example.com` / `password`

### 🎨 CMS機能
- **ポートフォリオ**: 8セクション個別編集・リアルタイムプレビュー
- **ブログ**: Markdownエディタ・一括操作・ステータス管理
- **メディア**: WebP自動変換・使用状況追跡・ストレージ管理
- **カテゴリ**: 2階層構造・ドラッグ&ドロップ並び替え
- **コメント**: 承認ワークフロー・スパム自動検知

### 🤖 AI統合機能
- **コンテンツ生成**: 記事要約・SEO最適化・関連記事提案
- **品質管理**: 文字数カウント・読了時間予測・スコアリング
- **運用効率化**: カテゴリ自動提案・タグ抽出・重複チェック
- **SEO強化**: メタデータ自動生成・キーワード密度最適化

### 💬 通知・連携機能
- **Slack統合**: お問い合わせ・新記事・エラー時リアルタイム通知
- **複数チャンネル対応**: 用途別チャンネル分散・通知ON/OFF制御
- **Analytics連携**: Google Analytics・Search Console統合

### 🔍 検索・発見機能
- **高度検索**: インクリメンタルサーチ・履歴・サジェスト
- **全文検索**: PostgreSQL・日本語対応・AND/OR検索
- **フィルタリング**: カテゴリ・タグ・日付・ステータス複合検索

### 🛡️ セキュリティ機能
- **2要素認証**: Google Authenticator・SMS対応
- **アクセス制御**: IP制限・ログイン試行制限・セッション管理
- **管理画面保護**: カスタムパス・メンテナンスモード

### 📊 運用・監視機能
- **システム監視**: サーバー・DB・SSL証明書・ストレージ監視
- **パフォーマンス**: 応答時間・可用性・エラー率追跡
- **自動バックアップ**: 日次/週次スケジュール・復元・履歴管理

## 🧪 テスト

```bash
# 全テスト実行
docker-compose exec app rspec

# 特定のテスト
docker-compose exec app rspec spec/models/article_spec.rb
```

## 📈 開発計画

### ✅ Phase 1: 仕様策定・プロトタイプ完了
- [x] **詳細仕様策定** - spec.md完成（650行超）
- [x] **16画面プロトタイプ完成** - フロントエンド5画面 + 管理画面11画面
- [x] **AI機能設計** - OpenAI API統合・SEO最適化・コンテンツ生成
- [x] **セキュリティ設計** - 2FA・IP制限・バックアップ・監視機能
- [x] **UI/UXデザインシステム** - ダークサイドバー・レスポンシブ対応

### 🚀 Phase 2: 開発実装（Sprint 0-3）
- [ ] **Sprint 0**: Rails 8.0環境構築・Docker設定・DB構築
- [ ] **Sprint 1**: 静的ページ実装・Tailwind CSS導入
- [ ] **Sprint 2**: 管理画面基盤・認証システム・ポートフォリオCMS
- [ ] **Sprint 3**: ブログ機能・Markdownエディタ・カテゴリ管理

### 🎯 Phase 3: 高度機能（Sprint 4-6）
- [ ] **Sprint 4**: AI機能統合・OpenAI API・SEO自動化
- [ ] **Sprint 5**: 検索機能・メディア管理・画像最適化
- [ ] **Sprint 6**: セキュリティ強化・監視機能・バックアップ

### 📊 Phase 4: 運用最適化（Sprint 7-8）
- [ ] **Sprint 7**: パフォーマンス最適化・キャッシュ・CDN統合
- [ ] **Sprint 8**: 本番デプロイ・監視設定・運用ドキュメント

詳細な技術仕様: `docs/specifications/spec.md`  
プロトタイプ一覧: `docs/wireframes/`

## 🤝 コントリビューション

このプロジェクトは個人サイトのため、外部からのコントリビューションは受け付けていません。

## 📄 ライセンス

Private Project - All Rights Reserved

## 📞 お問い合わせ

- サイト: https://miyakawa.code
- Email: contact@miyakawa.codes

---

## 🔄 更新履歴

- **2024-11-27**: 
  - ✅ **16画面プロトタイプ完成** - フロントエンド5画面 + 管理画面11画面
  - ✅ **spec.md大幅アップデート** - AI機能・セキュリティ・監視機能追加
  - ✅ **高度検索機能実装** - インクリメンタルサーチ・履歴・サジェスト
  - ✅ **SEO完全対応** - 構造化データ・sitemap・robots.txt管理UI
  - ✅ **運用監視機能** - システム監視・バックアップ・パフォーマンス追跡
  - ✅ **AI統合システム** - GPT-4・記事要約・SEO最適化・コンテンツ生成
  - ✅ **セキュリティ強化** - 2FA・IP制限・ログイン監視
- **2024-11-26**: 
  - プロジェクト開始・基本仕様策定完了
  - 3フェーズキャリア構成決定
  - 技術スタック確定（Rails 8.0.1 + AI機能）

---

## 📋 プロジェクト完了度

### ✅ 完了項目（Phase 1）
- **仕様策定**: 100% 完了
- **プロトタイプ**: 16/16画面 完了  
- **UI/UXデザイン**: 100% 完了
- **AI機能設計**: 100% 完了
- **セキュリティ設計**: 100% 完了

### 🎯 次のマイルストーン
**Phase 2開始**: Rails環境構築・Sprint 0実装開始