# Portfolio Ruby on Rails Project - Overview

## プロジェクト概要

### プロジェクト名
Portfolio & Technical Blog CMS

### 概要
シニアエンジニアの技術発信・ポートフォリオサイトをフルスクラッチで構築したRails 8.1.1プロジェクト。30年のキャリアを持つエンジニアが、最新技術を活用して構築した統合型CMSシステム。

### 技術スタック
- **Backend**: Ruby 3.4.7, Rails 8.1.1
- **Database**: PostgreSQL 17-alpine (Docker)
- **Frontend**: Tailwind CSS 3.x, Stimulus, Turbo (Hotwire)
- **Infrastructure**: Docker, Redis, Sidekiq 8.0
- **AI Integration**: OpenAI GPT API (ruby-openai 8.3.0)
- **Security**: Devise 4.9, JWT 3.1.2, Rack Attack
- **Monitoring**: Sentry, Solid Cache/Queue/Cable (Rails 8.1新機能)

### プロジェクトの特徴
1. **最新技術の採用**: Rails 8.1.1の新機能（Solid Cache/Queue/Cable）を全面活用
2. **Service Layer Pattern**: 22個のサービスクラスによる責務分離
3. **動的CMS**: JSONBベースの柔軟なコンテンツ管理
4. **セキュリティ重視**: 管理画面URL難読化、JWT認証、レート制限
5. **AI対応準備**: OpenAI API統合基盤構築済み

### プロジェクト規模
- **総ファイル数**: 182 Rubyファイル
- **マイグレーション数**: 20個
- **モデル数**: 15個
- **サービスクラス数**: 22個
- **コントローラー数**: 20個以上

### 開発期間
- **開始**: 2024年11月
- **現在**: Phase 3.3完了（約75%完成）
- **MVP予定**: 2025年12月中旬

### 主要機能
1. **ポートフォリオ機能**
   - 8つの動的セクション管理
   - バージョン管理機能
   - リアルタイムプレビュー

2. **技術ブログ機能**
   - Markdown対応エディタ
   - カテゴリ・タグ管理（階層構造）
   - 全文検索（PostgreSQL）
   - SEO最適化

3. **管理画面**
   - 完全なCRUD機能
   - ドラッグ&ドロップ並び替え
   - 一括操作機能
   - レスポンシブデザイン

4. **API機能**
   - RESTful公開API（/api/v1）
   - 認証付き内部API
   - レート制限実装

### プロジェクトURL
- **リポジトリ**: portfolio_rb
- **本番環境（予定）**: https://miyakawa.codes
- **インフラ**: AWS Lightsail（予定）

### 開発者情報
- **役職**: シニアエンジニア/プロジェクトマネージャー
- **経験**: 30年（講師→SE/PM→AIエンジニア）
- **専門**: 要件定義からプログラミングまで一貫対応

## ファイル構造概要

```
portfolio_rb/
├── app/
│   ├── controllers/     # 20+ controllers
│   ├── models/         # 15 models
│   ├── views/          # 完全実装済み
│   ├── services/       # 22 service classes
│   └── javascript/     # Stimulus controllers
├── config/
│   ├── routes.rb       # 完全なルーティング
│   └── database.yml    # PostgreSQL設定
├── db/
│   ├── migrate/        # 20 migrations
│   └── schema.rb       # 完全なスキーマ定義
├── docs/               # 包括的なドキュメント
├── spec/              # RSpec準備済み
└── docker-compose.yml  # Docker環境