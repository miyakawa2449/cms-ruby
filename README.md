# ポートフォリオ・ブログサイト

シニアエンジニアの技術発信・ポートフォリオサイト（CMS機能付き）

## 📋 概要

要件定義からプログラミングまで一貫して対応できるシニアエンジニアの技術発信サイトです。
縦スクロール型のポートフォリオページと、本格的な技術ブログ機能を搭載しています。

### 主な特徴
- 🎨 **セクション管理型CMS** - ポートフォリオの各セクションを個別管理
- 📝 **Markdownブログ** - 技術記事の執筆に最適化
- 🔍 **全文検索機能** - PostgreSQL + 日本語対応
- 🤖 **AI支援** - GPTによる記事要約・キーワード抽出
- 📱 **レスポンシブ対応** - モバイルファースト設計
- 🔒 **セキュリティ重視** - 管理画面パス変更可能
- 💬 **Slack連携** - お問い合わせの即時通知

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
- **OpenAI API** - 記事要約・AI支援機能
- **Slack Webhook** - お問い合わせ通知

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
│   ├── wireframes/                     # 画面設計
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

### 管理画面
```
/{admin_path}                          # ダッシュボード（パス変更可能）
├── /dashboard                         # 統計・概要
├── /articles                          # ブログ記事管理
├── /categories                        # カテゴリ管理  
├── /media                             # メディアライブラリ
├── /sections                          # ポートフォリオセクション
├── /seo                               # SEO設定
└── /settings                          # システム設定
    ├── /general                       # 一般設定
    ├── /security                      # セキュリティ
    └── /admin-path                    # 管理画面パス変更
```

## 🚀 セットアップ

### 必要な環境
- Ruby 3.4.0+
- PostgreSQL 14+
- Docker Desktop（推奨）
- OpenAI API Key

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
   # 必要な設定
   # - OpenAI API Key
   # - Slack Webhook URL（オプション）
   ```

### 本番環境デプロイ

詳細は `docs/deployment.md` を参照

## 📖 使用方法

### 管理画面アクセス
1. `http://localhost:3000/admin` （デフォルト）
2. 初期ユーザー: `admin@example.com` / `password`

### CMS機能
- ポートフォリオの各セクションを個別編集
- ブログ記事のMarkdown作成
- メディアファイルの一括管理

### Slack連携機能
- お問い合わせフォーム送信時に即時Slack通知
- 管理画面でWebhook URL設定
- メール + Slack のダブル受信で見逃し防止

### AI支援機能
- 記事保存時の要約自動生成
- SEOキーワード提案
- 関連記事の自動リンク

## 🧪 テスト

```bash
# 全テスト実行
docker-compose exec app rspec

# 特定のテスト
docker-compose exec app rspec spec/models/article_spec.rb
```

## 📈 開発計画

### Phase 1: 基盤構築（Sprint 0-1）
- [x] 仕様策定
- [ ] 環境構築
- [ ] 静的ページ実装

### Phase 2: CMS機能（Sprint 2-3）
- [ ] 管理画面
- [ ] ブログ基本機能

### Phase 3: 拡張機能（Sprint 4-5）
- [ ] メディア管理
- [ ] 検索機能

詳細は `docs/specifications/spec.md` を参照

## 🤝 コントリビューション

このプロジェクトは個人サイトのため、外部からのコントリビューションは受け付けていません。

## 📄 ライセンス

Private Project - All Rights Reserved

## 📞 お問い合わせ

- サイト: https://miyakawa.code
- Email: contact@miyakawa.codes

---

## 🔄 更新履歴

- 2024-11-26: プロジェクト開始・仕様策定完了