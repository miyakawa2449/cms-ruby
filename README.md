# 🚀 Portfolio Site CMS - シニアエンジニア技術発信プラットフォーム

[![Rails](https://img.shields.io/badge/Rails-8.1.1-red.svg)](https://rubyonrails.org/)
[![Ruby](https://img.shields.io/badge/Ruby-3.4.7-red.svg)](https://www.ruby-lang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-blue.svg)](https://www.postgresql.org/)
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
- **Rails**: 8.1.1（最新版・新機能活用）
- **データベース**: PostgreSQL 17-alpine（ICUロケール・全文検索最適化）
- **認証**: Devise 4.9.4 + JWT 3.1.2（セキュリティ強化済み）
- **認可**: Pundit 2.5.2
- **バックグラウンド**: Sidekiq 8.0.10 + sidekiq-cron 2.3.1

### フロントエンド
- **CSS**: Tailwind CSS 4.1.17（cssbundling-rails・最新版）
- **JavaScript**: Stimulus + Turbo（Rails 8.1標準）
- **アセット**: Propshaft（Rails 8.1標準）

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
- **SSL**: Let's Encrypt（設定予定）

## 📊 プロジェクト完了度

### ✅ 完了済みフェーズ
- **Phase 1**: 100% 完了（仕様策定・17画面プロトタイプ・API設計）
- **Phase 2A**: 100% 完了（Rails環境構築・設定ファイル）
- **Phase 2B**: 100% 完了（データベース基盤・フロントエンド統合）
- **Phase 2C-R**: 100% 完了（Rails 8.1.1再構築・セキュリティ問題全解決）
- **Phase 2C**: 100% 完了（CMS基盤・認証システム・記事/カテゴリ/タグ管理）

### 🚀 次期実行予定
- **Phase 3**: セクション管理・公開API実装・フロントエンド統合

### 📈 総合進捗: 約55%完了

### 🎯 Phase 2C完成機能
- ✅ **認証システム**: Devise + AdminUser + ログイン画面
- ✅ **記事管理**: 作成・編集・削除・公開・下書き・タグ/カテゴリ連携
- ✅ **カテゴリ管理**: 階層構造・CRUD・記事数カウント・デザイン設定
- ✅ **タグ管理**: CRUD・検索・記事数カウント・関連記事表示
- ✅ **管理画面**: レスポンシブナビゲーション・Tailwind CSS統合
- ✅ **モデル改善**: slug重複解決・リアルタイム更新・安全削除機能

## 🚀 セットアップ・開発環境構築

### 前提条件
```bash
# 必要なソフトウェア
- Ruby 3.4.7
- Node.js 18+ 
- PostgreSQL 17+
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
- **PostgreSQL**: 17-alpine（ICUロケール対応・日本語ソート改善）
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
- [Phase計画書](docs/development/phase_plan_rails_8_1.md) - Rails 8.1.1版開発計画
- [データベース設計v2](docs/database/schema_design_v2.md) - Rails 8.1対応版
- [API設計](docs/api/api_design.md) - 公開API + 内部API仕様

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

### Sprint 1-2: コアCMS機能（2024-12-09〜2024-12-20）
- ポートフォリオCMS完全実装
- ブログCMS完全実装
- 管理画面統合

### Sprint 3-4: 高度機能（2024-12-23〜2025-01-03）
- AI機能（GPT-4連携）
- 全文検索機能
- メディア管理

### Sprint 5-6: API・外部連携（2025-01-06〜2025-01-17）
- 公開API実装
- Slack連携
- 外部サービス統合

### Sprint 7-8: SEO・パフォーマンス（2025-01-20〜2025-01-31）
- 構造化データ
- キャッシュ戦略
- パフォーマンス最適化

### Sprint 9-11: 本番リリース（2025-02-03〜2025-02-28）
- セキュリティ監査
- 本番デプロイ
- SSL設定・最終調整

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