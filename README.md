# 🚀 Portfolio Site CMS - シニアエンジニア技術発信プラットフォーム

[![Rails](https://img.shields.io/badge/Rails-8.0.4-red.svg)](https://rubyonrails.org/)
[![Ruby](https://img.shields.io/badge/Ruby-3.4.7-red.svg)](https://www.ruby-lang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

シニアエンジニアの技術発信・ポートフォリオサイトをCMS化するプロジェクトです。

## 📋 プロジェクト概要

### 🎯 目的
- 技術発信の効率化・品質向上
- ポートフォリオの動的管理・SEO最適化
- AI連携による記事分析・自動最適化
- 管理画面による簡単コンテンツ管理

### 🏗 主要機能
1. **ポートフォリオCMS**: 8セクション構成の縦スクロール型サイト
2. **技術ブログ**: Markdown + カテゴリ階層 + 全文検索
3. **メディアライブラリ**: 画像管理・WebP最適化・遅延読み込み
4. **SEO/AEO最適化**: 構造化データ・meta tags・AI分析
5. **管理画面**: セキュリティ強化・権限管理

## 🛠 技術スタック

### バックエンド
- **Ruby**: 3.4.7
- **Rails**: 8.0.4（安定版・本番実績重視）
- **データベース**: PostgreSQL 16-alpine（ICUロケール・全文検索最適化・安定性確保）
- **認証**: Devise 4.9.4 + JWT 3.1.2（セキュリティ強化済み）
- **認可**: Pundit 2.5.2
- **バックグラウンド**: Sidekiq 8.0.10 + sidekiq-cron 2.3.1

### フロントエンド
- **CSS**: Tailwind CSS 4.1.17（cssbundling-rails・最新版）
- **JavaScript**: Stimulus + Turbo（Rails 8.0標準）
- **アセット**: Propshaft（Rails 8.0標準）

### AI・外部連携
- **AI**: ruby-openai 8.3.0（GPT-4連携・記事分析・SEO最適化）
- **HTTP**: HTTParty 0.23.2
- **検索**: pg_search 2.3.7（PostgreSQL全文検索）

### 開発・テスト・品質管理
- **テスト**: RSpec Rails 6.1 + FactoryBot + Faker
- **品質**: RuboCop Rails Omakase + Brakeman 7.1.1
- **CI/CD**: GitHub Actions（actions/checkout v6）
- **監視**: Sentry Rails 5.28.1

### インフラ・デプロイ
- **本番環境**: AWS Lightsail
- **コンテナ**: Docker + Kamal 1.9.3
- **Webサーバー**: Nginx + Puma 7.1.0
- **SSL**: Let's Encrypt（AWS Lightsailで設定済み）

## 📊 プロジェクト完了度

### ✅ 完了済みフェーズ
- **Phase 1**: 100% 完了（仕様策定・17画面プロトタイプ・API設計）
- **Phase 2A**: 100% 完了（Rails環境構築・設定ファイル）
- **Phase 2B**: 100% 完了（データベース基盤・フロントエンド統合）
- **Phase 2C-R**: 100% 完了（Rails 8.0.4安定化・セキュリティ問題全解決）
- **Phase 2C**: 100% 完了（CMS基盤・認証システム・記事/カテゴリ/タグ管理）
- **Phase 3.1**: 100% 完了（セクション管理CRUD実装）
- **Phase 3.2**: 100% 完了（コンタクトフォーム実装）
- **Phase 3.3**: 100% 完了（公開API実装）
- **Phase 3.4**: 100% 完了（フロントエンド統合・Works機能・データ構造最適化）

### 🚀 次期実行予定（MVP最終統合）
- **Phase 3.5-MVP**: 最終統合・公開準備（2025-12-12〜12-14）
- **MVP公開目標**: 2025-12-14-15日

### 📈 総合進捗: 約90%完了

### 🎯 Phase 3-4完成機能
- ✅ **セクション管理**: 8セクションCRUD・JSONB・バージョン管理・管理画面統合
- ✅ **コンタクトフォーム**: DB・非同期送信・Stimulus・管理画面・Slack通知準備
- ✅ **公開API**: /api/v1・Articles/Categories/Tags/Sections・検索・ページネーション
- ✅ **フロントエンド統合**: About/My Story/Works/Blog完全統合・Article連携
- ✅ **Works機能**: プロジェクト管理・技術スタック・Article連携・カード表示
- ✅ **データ構造最適化**: 個別フィールド化・Active Storage準備・OGP基盤

## 🚀 セットアップ・開発環境構築

### 前提条件
```bash
# 必要なソフトウェア
- Ruby 3.4.7
- Node.js 18+ 
- PostgreSQL 16+（安定性重視）
- Redis 7+（Sidekiq用）
```

### インストール・セットアップ
```bash
# 1. リポジトリクローン
git clone https://github.com/miyakawa2449/cms-ruby.git
cd cms-ruby

# 2. 依存関係インストール
bundle install

# 3. データベースセットアップ
rails db:create db:migrate db:seed

# 4. 開発サーバー起動
rails server
```

### 🐳 Docker開発環境（推奨）
```bash
# 1. Docker環境構築・起動
docker-compose up -d

# 2. データベースセットアップ
docker-compose exec web rails db:create db:migrate db:seed

# 3. サンプルデータ投入（オプション）
docker-compose exec web rails runner "load 'db/seeds/sample_data.rb'"

# 4. Railsサーバー起動（entrypoint問題回避）
docker-compose exec -d web bundle exec rails server -b 0.0.0.0
```

**Docker環境仕様**:
- **PostgreSQL**: 16-alpine（ICUロケール対応・安定性確保）
- **Redis**: 7-alpine（Sidekiq用）
- **Tailwind CSS**: 4.1.17（cssbundling-rails・watch対応）
```

### 🔐 管理画面アクセス
```
URL: http://localhost:3000/admin_users/sign_in
Email: admin@portfolio.dev
Password: password123
```

## 🧪 テスト実行

```bash
# RSpecテストスイート実行
bundle exec rspec

# セキュリティ監査
bundle exec brakeman

# コード品質チェック
bundle exec rubocop

# 全体テスト（CI/CD同等）
bin/ci
```

## 📚 ドキュメント

### 主要設計書
- [総合仕様書](docs/specifications/spec.md) - プロジェクト全体仕様（999行）
- [Phase計画書](docs/development/phase_plan_rails_8_1_1.md) - Rails 8.1.1版開発計画（最新版）
- [データベース設計v2](docs/database/schema_design_v2.md) - Rails 8.1対応版
- [API設計](docs/api/api_design.md) - 公開API + 内部API仕様
- [デプロイ前検討事項](docs/development/TODO_DEPLOY.md) - 本番リリース前の確認項目

### プロトタイプ（17画面完成）
- [フロントエンド画面](docs/wireframes/app/views/) - ポートフォリオ・ブログUI
- [管理画面](docs/wireframes/app/views/admin/) - CMS管理インターフェース

## 🔄 開発ワークフロー

### Gitワークフロー
```bash
# feature ブランチでの開発
git checkout -b feature/new-feature
git add .
git commit -m "feat: 新機能実装"
git push origin feature/new-feature

# Pull Request → Code Review → Merge
```

### デプロイフロー
```bash
# 本番デプロイ（Kamal使用）
kamal deploy

# 設定確認
kamal config
```

## 🎯 マイルストーン・リリース計画

### Phase 3.5-MVP: 最終統合（2025-12-12〜2025-12-14）実行中
- Docker環境修復・データ再構築
- My Story独立ページ実装（/my-story）
- エラーページ作成（404/500）
- 最終統合テスト・本番デプロイ準備
- **MVP公開**: 2025-12-14-15日

### Phase 4: 検索・最適化（2025-12-14〜2025-12-20）
- 基本検索機能実装
- パフォーマンス最適化
- UI/UX改善

### Phase 5: AI・高度機能（2026-01-06〜2026-01-31）
- AI機能（GPT-4連携・記事分析）
- 高度な検索（全文検索）
- メディア管理（画像最適化）

### Phase 6: 運用・セキュリティ（2026-02-01〜2026-02-28）
- セキュリティ監査
- 監視・自動バックアップ
- 継続的改善


## 🔒 セキュリティ対策

### 実装済み対策
- **認証**: Devise + 二要素認証（予定）
- **認可**: Pundit（ロールベース権限管理）
- **セキュリティヘッダー**: Rack::Attack + CSP
- **入力検証**: Strong Parameters + バリデーション
- **SQLインジェクション対策**: ActiveRecord ORM
- **XSS対策**: Rails標準エスケープ

### 監視・監査
- **静的解析**: Brakeman（脆弱性検出）
- **依存関係監査**: bundler-audit
- **セキュリティアップデート**: Dependabot自動監視

## 📈 監視・ログ

### 本番監視
- **エラー監視**: Sentry Rails
- **パフォーマンス**: Rails標準メトリクス
- **ログ管理**: Rails標準ログ + 構造化ログ

### 開発環境
- **デバッグ**: better_errors + binding_of_caller
- **メール確認**: letter_opener
- **ファイル監視**: listen

## 🤝 コントリビューション

### 開発に参加する場合
1. Issues確認・作成
2. Feature branchで開発
3. テスト実行・品質チェック
4. Pull Request作成
5. Code Review

### コードスタイル
- RuboCop Rails Omakaseに準拠
- RSpecテスト必須
- コミットメッセージ: Conventional Commits

## 📄 ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照

## 👨‍💻 開発者

**Tsuyoshi Miyakawa**  
Senior Software Engineer  

- 🌐 Website: [portfolio.miyakawa.dev](https://portfolio.miyakawa.dev)（本プロジェクトの成果物）
- 📧 Email: contact@miyakawa.dev
- 💼 LinkedIn: [linkedin.com/in/tsuyoshi-miyakawa](https://linkedin.com/in/tsuyoshi-miyakawa)

## 📈 プロジェクト統計

- **開発期間**: 2024-11-26 〜 2025-02-28（予定）
- **総コミット数**: 50+ commits
- **実装画面数**: 17画面（プロトタイプ完成済み）
- **データベーステーブル数**: 18+2テーブル
- **API エンドポイント数**: 30+ endpoints（設計済み）
- **テスト カバレッジ**: 90%+ 目標

---

**🚀 最新の開発状況は [GitHub Projects](https://github.com/miyakawa2449/cms-ruby/projects) で確認できます！**