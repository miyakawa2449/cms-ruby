# Phase 7.4: セキュリティ監査自動化 - Claude Code実装指示書

## 📅 作成日: 2026-02-03
## 🎯 Phase: 7.4
## 👨‍💻 実装担当: Claude Code
## 📊 ステータス: 実装待ち

---

## 🎯 実装概要

Phase 7.4では、セキュリティ脆弱性を自動検知し、継続的なセキュリティ監査を実現します。

### 主要機能
1. **静的解析自動化**: Brakeman、bundler-audit CI/CD統合
2. **依存関係監査**: Dependabot設定最適化
3. **ログ監視・アラート**: 不正アクセス検知、エラー率監視
4. **セキュリティレポート**: 週次レポート自動生成

### 実装期間
- **予定**: 5日間（2026-02-16 〜 2026-02-20）

---

## 📚 必読ドキュメント

実装前に以下のドキュメントを必ず確認してください：

1. **要件定義書**: `requirements.md`
   - ユーザーストーリー
   - 機能要件
   - 受け入れ基準

2. **設計書**: `design.md`
   - アーキテクチャ
   - コンポーネント設計
   - データモデル
   - API設計

3. **タスクリスト**: `tasks.md`
   - 実装タスク一覧
   - 進捗管理

4. **Phase 7.8 通知機能**:
   - `../phase-7-security-operations/requirements.md`
   - SecurityMailer、SlackNotifierの既存実装を確認

---

## 🚀 実装の進め方

### ステップ1: データベース設計（Day 1）

#### 1.1 マイグレーション作成

```bash
# SecurityScanモデル
rails g model SecurityScan scan_type:integer status:integer raw_results:jsonb scanned_at:datetime error_message:text

# Vulnerabilityモデル
rails g model Vulnerability security_scan:references severity:integer title:string description:text file_path:string line_number:integer gem_name:string gem_version:string cve_id:string patched_versions:string fixed:boolean fixed_at:datetime

# SecurityReportモデル
rails g model SecurityReport report_type:integer status:integer period_start:datetime period_end:datetime data:jsonb generated_at:datetime
```

#### 1.2 マイグレーション編集

設計書の「データモデル」セクションを参照して、以下を追加：
- インデックス
- デフォルト値
- NOT NULL制約
- 外部キー制約

#### 1.3 モデル実装

設計書の実装例を参照して、以下を実装：
- enum定義
- アソシエーション
- バリデーション
- スコープ
- メソッド

#### 1.4 マイグレーション実行

```bash
rails db:migrate
```

---

### ステップ2: Serviceクラス実装（Day 2）

#### 2.1 Security::ScannerService

**ファイル**: `app/services/security/scanner_service.rb`

設計書の実装例を参照して実装してください。

**重要なポイント**:
- Brakemanの結果パース
- bundler-auditの結果パース
- 重大度マッピング
- 通知送信（SecurityMailer、SlackNotifier）

#### 2.2 Security::ReporterService

**ファイル**: `app/services/security/reporter_service.rb`

設計書の実装例を参照して実装してください。

**重要なポイント**:
- スキャンデータ収集
- 脆弱性データ収集
- インシデントデータ収集
- レポート送信

#### 2.3 Security::MonitorService

**ファイル**: `app/services/security/monitor_service.rb`

設計書の実装例を参照して実装してください。

**重要なポイント**:
- エラー率監視
- トラフィック異常検知
- アラート送信

---

### ステップ3: Internal API実装（Day 2）

#### 3.1 コントローラー作成

**ファイル**: `app/controllers/api/internal/security_controller.rb`

設計書の実装例を参照して実装してください。

**重要なポイント**:
- API認証（INTERNAL_API_TOKEN）
- brakemanアクション
- bundler_auditアクション
- エラーハンドリング

#### 3.2 ルーティング設定

**ファイル**: `config/routes.rb`

```ruby
namespace :api do
  namespace :internal do
    resource :security, only: [] do
      post :brakeman
      post :bundler_audit
    end
  end
end
```

---

### ステップ4: GitHub Actions実装（Day 3）

#### 4.1 ワークフローファイル作成

**ファイル**: `.github/workflows/security-audit.yml`

設計書の実装例を参照して実装してください。

**重要なポイント**:
- スケジュール実行（cron）
- プルリクエストトリガー
- Brakemanジョブ
- bundler-auditジョブ
- アーティファクトアップロード
- 通知送信（失敗時）

#### 4.2 GitHub Secrets設定

以下のSecretsを設定してください：
- `RAILS_WEBHOOK_URL`: 本番環境のURL
- `INTERNAL_API_TOKEN`: 強力なトークン（32文字以上）

**トークン生成例**:
```ruby
SecureRandom.hex(32)
```

#### 4.3 動作確認

1. 手動実行テスト（workflow_dispatch）
2. プルリクエスト作成テスト
3. スケジュール実行確認（翌日）

---

### ステップ5: Dependabot設定（Day 3）

#### 5.1 dependabot.yml作成

**ファイル**: `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: "bundler"
    directory: "/"
    schedule:
      interval: "daily"
    labels:
      - "dependencies"
      - "security"
    open-pull-requests-limit: 10

  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "daily"
    labels:
      - "dependencies"
      - "security"
    open-pull-requests-limit: 10
```

#### 5.2 自動マージ設定（オプション）

**ファイル**: `.github/workflows/dependabot-auto-merge.yml`

パッチバージョンアップデートの自動マージを設定してください。

---

### ステップ6: Mailer拡張（Day 4）

#### 6.1 SecurityMailer拡張

**ファイル**: `app/mailers/security_mailer.rb`

Phase 7.8で実装済みのSecurityMailerに以下のメソッドを追加：
- `security_alert`
- `high_error_rate_alert`
- `traffic_spike_alert`

設計書の実装例を参照してください。

#### 6.2 メールテンプレート作成

以下のビューファイルを作成：
- `app/views/security_mailer/security_alert.html.erb`
- `app/views/security_mailer/high_error_rate_alert.html.erb`
- `app/views/security_mailer/traffic_spike_alert.html.erb`

**デザイン**: Phase 7.8のメールテンプレートを参考にしてください。

---

### ステップ7: 管理画面実装（Day 4）

#### 7.1 コントローラー作成

**ファイル**:
- `app/controllers/admin/security_scans_controller.rb`
- `app/controllers/admin/security_reports_controller.rb`

**アクション**:
- index（一覧）
- show（詳細）
- download（PDF、SecurityReportsのみ）

#### 7.2 ビュー作成

**ファイル**:
- `app/views/admin/security_scans/index.html.erb`
- `app/views/admin/security_scans/show.html.erb`
- `app/views/admin/security_reports/index.html.erb`
- `app/views/admin/security_reports/show.html.erb`

**デザイン**: 既存の管理画面デザインに統一してください。

#### 7.3 Chart.js統合

脆弱性の重大度別グラフを表示してください。

**参考**: Phase 5.5のAI使用量ダッシュボード実装を参照。

#### 7.4 ナビゲーション追加

**ファイル**: `app/views/layouts/admin.html.erb`

管理画面メニューに「セキュリティ」セクションを追加してください。

---

### ステップ8: Sidekiq-cron設定（Day 4）

#### 8.1 Jobクラス作成

**ファイル**: `app/jobs/security/weekly_report_job.rb`

```ruby
module Security
  class WeeklyReportJob < ApplicationJob
    queue_as :default
    
    def perform
      Security::ReporterService.new.generate_weekly_report
    rescue StandardError => e
      Rails.logger.error("Weekly security report failed: #{e.message}")
      raise
    end
  end
end
```

#### 8.2 recurring.yml設定

**ファイル**: `config/recurring.yml`

```yaml
weekly_security_report:
  cron: "0 10 * * 1" # 毎週月曜日午前10時JST
  class: "Security::WeeklyReportJob"
  queue: default
  description: "Generate and send weekly security report"
```

---

### ステップ9: テスト実装（Day 5）

#### 9.1 モデルテスト

**ファイル**:
- `spec/models/security_scan_spec.rb`（5件）
- `spec/models/vulnerability_spec.rb`（5件）
- `spec/models/security_report_spec.rb`（3件）

**テスト内容**:
- バリデーション
- アソシエーション
- スコープ
- メソッド

#### 9.2 Serviceテスト

**ファイル**:
- `spec/services/security/scanner_service_spec.rb`（8件）
- `spec/services/security/reporter_service_spec.rb`（5件）
- `spec/services/security/monitor_service_spec.rb`（4件）

設計書の「テスト設計」セクションを参照してください。

#### 9.3 コントローラーテスト

**ファイル**:
- `spec/requests/api/internal/security_spec.rb`（6件）
- `spec/requests/admin/security_scans_spec.rb`（4件）
- `spec/requests/admin/security_reports_spec.rb`（4件）

#### 9.4 Mailerテスト

**ファイル**:
- `spec/mailers/security_mailer_spec.rb`（3件）

#### 9.5 Jobテスト

**ファイル**:
- `spec/jobs/security/weekly_report_job_spec.rb`（2件）

#### 9.6 統合テスト

**ファイル**:
- `spec/integration/security_audit_flow_spec.rb`

スキャン→通知フロー、レポート生成フローをテストしてください。

#### 9.7 テスト実行

```bash
bundle exec rspec
```

**目標**: 全テスト成功、カバレッジ85%以上

---

## 🔒 セキュリティ要件

### 1. API認証

- INTERNAL_API_TOKENは強力なトークンを使用（32文字以上）
- GitHub Secretsに保存
- 本番環境とステージング環境で異なるトークンを使用

### 2. 機密情報の除外

- スキャン結果からパスワード、トークン等を除外
- メール通知はサマリーのみ
- 詳細は管理画面でのみ閲覧可能

### 3. アクセス制御

- 管理画面は認証必須
- 管理者のみアクセス可能
- 監査ログの記録

---

## 📝 実装時の注意事項

### 1. Phase 7.8（通知機能）との統合

Phase 7.8で実装済みの以下を活用してください：
- `SecurityMailer`（brakeman_issues, bundler_audit_issues, weekly_report）
- `SlackNotifier`（notify_security_issue）

### 2. 既存コードの確認

以下の既存実装を確認してください：
- `app/services/security_logger.rb`（Phase 6で実装）
- `config/initializers/rack_attack.rb`（Phase 6で実装）

### 3. エラーハンドリング

- すべてのServiceクラスで適切なエラーハンドリング
- ログ記録（Rails.logger）
- 通知送信（失敗時）

### 4. パフォーマンス

- スキャン実行時間: 10分以内
- レポート生成時間: 3分以内
- データベースクエリの最適化

---

## ✅ 完了基準

### 1. 機能要件

- [ ] Brakemanが日次で自動実行される
- [ ] bundler-auditが日次で自動実行される
- [ ] 脆弱性発見時にメール・Slack通知が送信される
- [ ] 週次レポートが自動生成される
- [ ] 管理画面でスキャン結果・レポートが閲覧できる

### 2. テスト要件

- [ ] RSpecテスト10件以上実装
- [ ] 全テスト成功
- [ ] テストカバレッジ85%以上

### 3. ドキュメント要件

- [ ] セキュリティ監査手順書作成
- [ ] トラブルシューティングガイド作成
- [ ] 脆弱性対応フロー作成

---

## 🔄 実装完了後の手順

### 1. Codexへの引き継ぎ

実装完了後、以下を実施してください：

1. **全テスト実行**
   ```bash
   bundle exec rspec
   ```

2. **Codexへの通知**
   - 実装完了を報告
   - テスト結果を共有
   - 検証依頼

### 2. Codexによる検証

Codexが以下を実施します：
- セキュリティチェック（Brakeman、bundler-audit）
- テスト実行・検証
- 既存機能への影響確認
- 検証レポート作成

### 3. Kiroによる受け入れ

Kiroが以下を実施します：
- 要件との照合
- 設計書との照合
- 受け入れ基準の確認
- 最終承認

---

## 📚 参考資料

### 技術資料
- [Brakeman](https://brakemanscanner.org/)
- [bundler-audit](https://github.com/rubysec/bundler-audit)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Dependabot](https://docs.github.com/en/code-security/dependabot)

### 関連Phase
- Phase 6: セキュリティ強化（SecurityLogger、Rack::Attack）
- Phase 7.8: 通知機能（SecurityMailer、SlackNotifier）

---

## 💬 質問・相談

実装中に不明点がある場合は、以下を確認してください：

1. **要件定義書**: `requirements.md`
2. **設計書**: `design.md`
3. **タスクリスト**: `tasks.md`

それでも不明な場合は、人（ユーザー）に確認してください。

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-02-03  
**🔄 バージョン**: v1.0  
**📋 ステータス**: 実装待ち  
**👨‍💻 実装担当**: Claude Code  
**🔍 検証担当**: Codex  
**✅ 受け入れ担当**: Kiro
