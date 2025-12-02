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
- **Ruby** 3.4.7
- **Ruby on Rails** 8.0.4
- **PostgreSQL** 16 - メインデータベース
- **Redis** 7 - キャッシュ・Sidekiq
- **Sidekiq** - バックグラウンドジョブ（AI処理）

### Frontend
- **Tailwind CSS** - ユーティリティファースト
- **ESBuild** - JavaScript バンドラー
- **Turbo** - SPA風エクスペリエンス
- **Stimulus** - 軽量JavaScriptフレームワーク

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
├── Gemfile                            # 65 gems設定済み（Rails 8.0.4対応）
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
│   ├── development/
│   │   ├── phase_2_revision_plan.md    # Phase 2計画見直し
│   │   └── gem_dependencies.md         # Gem依存関係ドキュメント
│   ├── wireframes/                     # 画面設計プロトタイプ（17画面）
│   │   ├── portfolio_prototype.html    # ポートフォリオトップ
│   │   ├── my_story_prototype.html     # My Storyページ
│   │   ├── blog_top_prototype.html     # ブログトップ（高度検索付き）
│   │   ├── blog_article_prototype.html # 記事詳細
│   │   ├── blog_category_prototype.html # カテゴリページ
│   │   └── app/views/admin/            # 管理画面プロトタイプ
│   │       ├── auth/admin_login_prototype.html           # ログイン画面
│   │       ├── dashboard/admin_dashboard_prototype.html  # ダッシュボード
│   │       ├── articles/admin_blog_prototype.html        # 記事管理
│   │       ├── articles/admin_article_editor_prototype.html # 記事エディタ（AI機能）
│   │       ├── categories/admin_categories_prototype.html # カテゴリ管理
│   │       ├── categories/admin_category_create_prototype.html # カテゴリ作成
│   │       ├── users/admin_users_prototype.html          # ユーザー管理
│   │       ├── comments/admin_comments_prototype.html    # コメント管理
│   │       ├── media/admin_media_prototype.html          # メディアライブラリ
│   │       ├── portfolio_cms/admin_portfolio_prototype.html # ポートフォリオCMS
│   │       └── settings/admin_settings_prototype.html    # 設定（8タブ構成）
│   ├── database/                       # データベース設計
│   │   ├── schema_design.md            # 18テーブル設計
│   │   ├── migrations_plan.md          # 20マイグレーション計画
│   │   └── er_diagram.mermaid          # ER図
│   ├── api/                            # API設計
│   │   └── api_design.md               # RESTful API設計書
│   ├── analysis/                       # 仕様分析ドキュメント
│   │   ├── spec_features.md            # spec.md機能一覧
│   │   ├── prototype_features.md       # プロトタイプ機能分析
│   │   └── gap_analysis.md            # 差分分析結果
│   └── tools/
│       └── daily_reports.md            # 日報システム使用方法
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

### 管理画面（17画面完備）
```
/{admin_path}                          # ダッシュボード（パス変更可能）
├── /auth/login                        # ログイン画面（NEW 2024-11-29）
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
- Ruby 3.4.7+
- PostgreSQL 16+
- Redis 7+
- Docker Desktop（推奨）
- **OpenAI API Key** - AI機能利用に必須
- **Slack Webhook URL** - リアルタイム通知機能（オプション）
- **Google Analytics ID** - アクセス解析（オプション）

### 開発環境構築

#### Phase 2A: ネットワーク不要セットアップ（2024-11-29 完了）
Phase 2A完了。全タスク1日で完了しました。

1. **リポジトリクローン**
   ```bash
   git clone [repository-url]
   cd portfolio_rb
   ```

2. **設定ファイル準備**
   ```bash
   cp .env.example .env
   # .envファイル編集（下記「環境変数設定」参照）
   ```

3. **Docker環境構築**
   ```bash
   docker-compose up -d
   ```

#### Phase 2B: gemインストール・動作確認（2025-12-02〜）
Ruby 3.4.7のHappy Eyeballs問題を解決し、作業開始。

4. **gemインストール**
   ```bash
   # Ruby 3.4.7でエラーが出る場合は環境変数を設定
   export RUBY_TCP_NO_FAST_FALLBACK=1
   bundle install  # 65 gems インストール ✅ 2025-12-02完了
   ```

5. **データベース初期化**
   ```bash
   docker-compose exec app rails db:create
   docker-compose exec app rails db:migrate
   docker-compose exec app rails db:seed
   ```

6. **開発サーバー起動**
   ```bash
   docker-compose exec app rails server
   ```

### 環境変数設定

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
DATABASE_URL=postgresql://user:pass@db:5432/portfolio_rb_development
REDIS_URL=redis://redis:6379/0
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

### ✅ Phase 1: 仕様策定・設計 (100% 完了)
- [x] **詳細仕様策定** - spec.md完成（1000行超）
- [x] **17画面プロトタイプ完成** - フロントエンド5画面 + 管理画面12画面
- [x] **AI機能設計** - OpenAI API統合・SEO最適化・コンテンツ生成
- [x] **セキュリティ設計** - 2FA・IP制限・バックアップ・監視機能
- [x] **UI/UXデザインシステム** - ダークサイドバー・レスポンシブ対応
- [x] **データベーススキーマ設計** - 18テーブル完全設計
- [x] **Railsマイグレーション計画** - 20マイグレーションファイル策定
- [x] **API設計完成** - 公開API + 内部API・RESTful設計

### 🚀 Phase 2: 開発実装 - Phase 2B実行中
#### ✅ Phase 2A: ネットワーク不要作業（2024-11-29 完了）
- [x] **Rails 8.0.4 環境構築完了** - PostgreSQL・Tailwind CSS・ESBuild・Docker
- [x] **Gemfile統合完了** - 65 gems設定（Rails 8.0.4対応）
- [x] **Phase 2計画見直し完了** - ネットワーク問題対応・Phase 2A/2B分割
- [x] **config/database.yml PostgreSQL設定完了**
- [x] **基本ルーティング設計完了**（config/routes.rb - 400+ lines）
- [x] **20個のマイグレーションファイル作成完了**
- [x] **基本コントローラー・モデル設計完了**
- [x] **Devise設定ファイル準備完了**
- [x] **RSpec設定ファイル準備完了**

#### ✅ Phase 2B: 80%完了（2025-12-02実行）
- [x] **bundle install実行（65 gems インストール）** ✅ 2025-12-02完了
  - Ruby 3.4.7 Happy Eyeballs問題を`RUBY_TCP_NO_FAST_FALLBACK=1`で解決
- [x] **Rails Templates統合完了（15ファイル）** ✅ 2025-12-02追加実行
  - SEO/AEO強化版レイアウト実装（meta tags, OG tags, 構造化データ）
  - フロントエンド5ページ完全実装（portfolio, my_story, blog×3）
  - JavaScript機能実装（scroll animations, progress bar）
  - Tailwind CSS統合（wireframesデザイン完全再現）
- [ ] Devise設定・認証実装
- [ ] データベース初期化・シードデータ投入  
- [ ] 実際の動作確認・テスト実行
- [ ] 本格開発開始準備完了

### 🎯 Phase 3: 基本実装（Sprint 1-3）
- [ ] **Sprint 1**: 静的ページ実装・基本ルーティング
- [ ] **Sprint 2**: 管理画面基盤・ポートフォリオCMS
- [ ] **Sprint 3**: ブログ機能・Markdownエディタ・カテゴリ管理

### 🔍 Phase 4: 検索・メディア（Sprint 4-5）
- [ ] **Sprint 4**: メディア管理・画像最適化・WebP自動変換
- [ ] **Sprint 5**: 全文検索実装・カテゴリページ・パンくずリスト

### 🔌 Phase 5: API機能実装（Sprint 6-7）
- [ ] **Sprint 6: 公開API実装**
  - ブログ記事API（記事一覧・詳細・カテゴリ・タグ）
  - ポートフォリオAPI（セクション・作品データ）
  - 検索API（インクリメンタルサーチ・サジェスト）
  - お問い合わせAPI（reCAPTCHA・Slack連携）
  - サイトマップ・RSS配信API
  - API認証・レート制限実装

- [ ] **Sprint 7: 内部管理API実装**
  - 記事管理API（CRUD・一括操作）
  - AI分析API（要約・SEO分析・関連記事提案）
  - メディア管理API（アップロード・最適化・使用状況）
  - API統計・ログ収集機能
  - フロントエンド統合（検索・フォーム・動的コンテンツ）

### 📊 Phase 6: SEO/最適化（Sprint 8-9）
- [ ] **Sprint 8**: SEO/OGP強化・メタデータ管理・構造化データ・sitemap自動生成
- [ ] **Sprint 9**: AI連携・キャッシュ最適化・OpenAI API統合・Redis戦略実装

### 🔧 Phase 7: 仕上げ・運用（Sprint 10+）
- [ ] **Sprint 10**: UIポリッシュ・ユーザビリティ改善・API ドキュメント自動生成
- [ ] **Sprint 11**: 本番デプロイ・監視設定・負荷テスト・セキュリティ監査

詳細な技術仕様: `docs/specifications/spec.md`  
プロトタイプ一覧: `docs/wireframes/`  
Phase 2計画詳細: `docs/development/phase_2_revision_plan.md`

## 🤝 コントリビューション

このプロジェクトは個人サイトのため、外部からのコントリビューションは受け付けていません。

## 📄 ライセンス

Private Project - All Rights Reserved

## 📞 お問い合わせ

- サイト: https://miyakawa.code
- Email: contact@miyakawa.codes

---

## 🔄 更新履歴

- **2025-12-02**:
  - ✅ **bundle install問題解決** - Ruby 3.4.7 Happy Eyeballs問題を環境変数で解決
  - ✅ **Phase 2B開始** - Gemfile.lock生成・220 gems インストール完了
- **2024-11-29**:
  - ✅ **Phase 2A完全完了（1日で達成）** - ネットワーク不要作業全て完了
  - ✅ **Phase 2計画見直し完了** - ネットワーク問題対応・Phase 2A/2B分割計画策定
  - ✅ **管理画面ログインページプロトタイプ追加** - 17画面完成
  - ✅ **Rails 8.0.4環境構築完了** - PostgreSQL・Tailwind CSS・ESBuild・Docker
  - ✅ **Gemfile統合完了** - 65 gems設定（Rails 8.0.4対応・annot8採用）
  - ✅ **技術スタック確定** - Ruby 3.4.7・Rails 8.0.4・PostgreSQL 16・Redis 7
  - ✅ **20マイグレーションファイル作成完了**
  - ✅ **ルーティング設計完了** - 400+ lines
  - ✅ **基本コントローラー・Devise・RSpec設定完了**

- **2024-11-28**:
  - ✅ **データベーススキーマ設計完了** - 18テーブル完全設計
  - ✅ **Railsマイグレーション計画完了** - 20マイグレーションファイル策定
  - ✅ **ER図作成** - 全テーブルリレーション可視化
  - ✅ **PostgreSQL特有機能活用** - 全文検索・JSONB・パーティショニング設計
  - ✅ **API設計完成・spec.md統合** - RESTful API（公開/内部）・既存機能との統合
  - ✅ **開発計画更新** - API実装フェーズ（Sprint 6-7）追加・11スプリント構成

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
- **プロトタイプ**: 17/17画面 完了  
- **UI/UXデザイン**: 100% 完了
- **AI機能設計**: 100% 完了
- **セキュリティ設計**: 100% 完了
- **データベース設計**: 100% 完了（18テーブル）
- **マイグレーション計画**: 100% 完了（20ファイル）
- **API設計**: 100% 完了（公開API + 内部API）
- **開発計画統合**: 100% 完了（11スプリント構成）

### ✅ Phase 2A完了（ネットワーク不要作業）
- **Rails 8.0.4環境構築**: 100% 完了
- **Gemfile統合**: 100% 完了（65 gems設定）
- **Phase 2計画見直し**: 100% 完了
- **config/database.yml設定**: 100% 完了
- **全タスク1日で完了**: 2024-11-29

### ⚡ Phase 2B実行中
- **bundle install**: 100% 完了（2025-12-02）
- **Devise設定・認証実装**: 次のタスク
- **データベース初期化**: 待機中

### 🎯 次のマイルストーン
**Phase 2A完了**: ✅ 2024-11-29（1日で完了）  
**Phase 2B実行**: ✅ 2025-12-02（フロントエンド統合80%完了・DB作業残り）  
**Sprint 1開始予定**: Phase 2B完了後（DB/認証完了次第）