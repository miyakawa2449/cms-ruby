# Portfolio Site CMS - シニアエンジニア技術発信プラットフォーム

[![Rails](https://img.shields.io/badge/Rails-8.1.1-red.svg)](https://rubyonrails.org/)
[![Ruby](https://img.shields.io/badge/Ruby-3.4.7-red.svg)](https://www.ruby-lang.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-blue.svg)](https://www.postgresql.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

シニアエンジニアの技術発信・ポートフォリオサイトをCMS化するプロジェクトです。

## プロジェクト概要

### 目的
- 技術発信の効率化・品質向上
- ポートフォリオの動的管理・SEO最適化
- AI連携による記事分析・自動最適化
- 管理画面による簡単コンテンツ管理

### 主要機能
1. **ポートフォリオCMS**: 8セクション構成の縦スクロール型サイト
2. **技術ブログ**: Markdown + カテゴリ階層 + 全文検索（pg_search）
3. **My Story**: キャリアタイムライン独立ページ
4. **メディアライブラリ**: 画像管理・編集（Cropper.js）・使用状況トラッキング
5. **本文内画像トリミング**: 800x600px固定出力・4:3アスペクト比・Markdown自動挿入
6. **コンタクトフォーム**: AWS SES連携・スパム対策
7. **管理画面**: Devise認証・権限管理

## 技術スタック

### バックエンド
| 技術 | バージョン | 用途 |
|------|-----------|------|
| Ruby | 3.4.7 | 言語 |
| Rails | 8.1.1 | フレームワーク |
| PostgreSQL | 17-alpine | データベース（ICUロケール・全文検索） |
| Redis | 7-alpine | キャッシュ・Sidekiq |
| Sidekiq | 8.0 | バックグラウンドジョブ |

### フロントエンド
| 技術 | 用途 |
|------|------|
| Tailwind CSS | スタイリング |
| Stimulus | JavaScript |
| Turbo | SPA風画面遷移 |
| Propshaft | アセット管理 |

### AWS統合
| サービス | 用途 |
|----------|------|
| Lightsail | 本番インフラ |
| SES | メール送信 |
| Bedrock | AI機能（予定） |

### 認証・セキュリティ
- **認証**: Devise + JWT 3.1
- **認可**: Pundit 2.3
- **セキュリティ**: Rack::Attack、Brakeman

## セットアップ

### 前提条件
- Ruby 3.4.7
- Node.js 18+
- PostgreSQL 17+
- Redis 7+

### Docker開発環境（推奨）
```bash
# 環境構築・起動
docker-compose up -d

# データベースセットアップ
docker-compose exec web rails db:create db:migrate db:seed

# Railsサーバー起動
docker-compose exec -d web bundle exec rails server -b 0.0.0.0
```

### ローカル開発環境
```bash
# 依存関係インストール
bundle install

# データベースセットアップ
rails db:create db:migrate db:seed

# 開発サーバー起動
rails server
```

### 管理画面アクセス
```
URL: http://localhost:3000/admin
Email: admin@portfolio.dev
Password: password123
```

## テスト実行

```bash
# RSpecテストスイート
bundle exec rspec

# セキュリティ監査
bundle exec brakeman

# コード品質チェック
bundle exec rubocop
```

## ドキュメント

### 📘 運用・管理
| ドキュメント | 説明 |
|-------------|------|
| [運用マニュアル](docs/OPERATION_MANUAL.md) | **必読**: Kiro/Claude Code併用運用ガイド |
| [クイックリファレンス](docs/QUICK_REFERENCE.md) | よく使う指示集・チートシート |
| [Phase計画書](docs/development/phase_plan_rails_8_1_1.md) | 開発計画・進捗 |
| [実装ログ](docs/development/implementation_log.md) | 実装履歴 |

### 🤖 AI設定ファイル
| ファイル | 対象AI | 説明 |
|---------|--------|------|
| [KIRO.md](KIRO.md) | **Kiro** | Kiro用メモリー・役割・作業フロー |
| [CLAUDE.md](CLAUDE.md) | **Claude Code** | Claude Code用メモリー・実装ガイド |

### 📋 仕様書
| ドキュメント | 説明 |
|-------------|------|
| [総合仕様書](docs/specifications/spec.md) | プロジェクト全体仕様 |
| [機能仕様書ガイド](docs/specifications/features/README.md) | 仕様書の書き方 |
| [機能仕様書テンプレート](docs/specifications/features/_TEMPLATE.md) | 新規仕様書作成用 |

### 🤖 AI用ドキュメント
| ドキュメント | 説明 |
|-------------|------|
| [Kiro用コンテキスト](docs/handoff/kiro_context.md) | Kiroの役割・作業フロー |
| [Claude Code用コンテキスト](docs/handoff/claude_context.md) | Claude Codeの役割・実装ガイド |
| [コーディング規約](docs/handoff/conventions.md) | 共通コーディング規約 |

### 🏗️ 設計書
| ドキュメント | 説明 |
|-------------|------|
| [データベース設計](docs/database/schema_design_v2.md) | テーブル設計 |
| [API設計](docs/api/api_design.md) | 公開API + 内部API仕様 |

## セキュリティ対策

### 実装済み
- **認証**: Devise + セッション管理
- **認可**: Pundit（ロールベース権限）
- **セキュリティヘッダー**: Rack::Attack + CSP
- **入力検証**: Strong Parameters + バリデーション
- **SQLインジェクション対策**: ActiveRecord ORM
- **XSS対策**: Rails標準エスケープ

### 監視・監査
- **静的解析**: Brakeman（脆弱性検出）
- **依存関係監査**: bundler-audit
- **エラー監視**: Sentry Rails

## 開発ワークフロー

```bash
# feature ブランチでの開発
git checkout -b feature/new-feature
git add .
git commit -m "feat: 新機能実装"
git push origin feature/new-feature
```

### コードスタイル
- RuboCop Rails Omakaseに準拠
- RSpecテスト必須
- コミットメッセージ: Conventional Commits

## ライセンス

MIT License - 詳細は [LICENSE](LICENSE) ファイルを参照

## 開発者

**Tsuyoshi Miyakawa**
Senior Software Engineer

---

詳細な開発状況は [Phase計画書](docs/development/phase_plan_rails_8_1_1.md) を参照してください。
