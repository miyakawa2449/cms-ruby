# Phase 7.4: セキュリティ監査自動化 - タスクリスト

## 📅 作成日: 2026-02-03
## 🎯 Phase: 7.4
## ⚡️ 優先度: 中
## 📊 ステータス: ✅ 完了

---

## 📋 タスク概要

- **総タスク数**: 9
- **完了タスク数**: 9
- **進捗率**: 100%
- **実施期間**: 2026-02-03

---

## ✅ タスクリスト

### 1. データベース設計・マイグレーション

- [ ] 1.1 SecurityScanモデル作成
  - [ ] 1.1.1 マイグレーションファイル作成
  - [ ] 1.1.2 モデルファイル作成
  - [ ] 1.1.3 enum定義（scan_type, status）
  - [ ] 1.1.4 バリデーション実装
  - [ ] 1.1.5 スコープ実装
  - [ ] 1.1.6 メソッド実装（high_severity_count, summary）

- [ ] 1.2 Vulnerabilityモデル作成
  - [ ] 1.2.1 マイグレーションファイル作成
  - [ ] 1.2.2 モデルファイル作成
  - [ ] 1.2.3 enum定義（severity）
  - [ ] 1.2.4 アソシエーション設定（belongs_to :security_scan）
  - [ ] 1.2.5 バリデーション実装
  - [ ] 1.2.6 スコープ実装
  - [ ] 1.2.7 メソッド実装（mark_as_fixed!）

- [ ] 1.3 SecurityReportモデル作成
  - [ ] 1.3.1 マイグレーションファイル作成
  - [ ] 1.3.2 モデルファイル作成
  - [ ] 1.3.3 enum定義（report_type, status）
  - [ ] 1.3.4 バリデーション実装
  - [ ] 1.3.5 スコープ実装
  - [ ] 1.3.6 メソッド実装（pdf_filename）

- [ ] 1.4 マイグレーション実行・確認
  - [ ] 1.4.1 開発環境でマイグレーション実行
  - [ ] 1.4.2 テーブル作成確認
  - [ ] 1.4.3 インデックス確認

---

### 2. Serviceクラス実装

- [ ] 2.1 Security::ScannerService実装
  - [ ] 2.1.1 基本構造作成
  - [ ] 2.1.2 processメソッド実装
  - [ ] 2.1.3 create_scanメソッド実装
  - [ ] 2.1.4 parse_resultsメソッド実装
  - [ ] 2.1.5 parse_brakeman_resultsメソッド実装
  - [ ] 2.1.6 parse_bundler_audit_resultsメソッド実装
  - [ ] 2.1.7 notify_if_vulnerabilitiesメソッド実装
  - [ ] 2.1.8 map_brakeman_severityメソッド実装
  - [ ] 2.1.9 map_bundler_audit_severityメソッド実装
  - [ ] 2.1.10 format_vulnerabilitiesメソッド実装

- [ ] 2.2 Security::ReporterService実装
  - [ ] 2.2.1 基本構造作成
  - [ ] 2.2.2 generate_weekly_reportメソッド実装
  - [ ] 2.2.3 collect_scan_dataメソッド実装
  - [ ] 2.2.4 collect_vulnerability_dataメソッド実装
  - [ ] 2.2.5 collect_incident_dataメソッド実装
  - [ ] 2.2.6 send_reportメソッド実装

- [ ] 2.3 Security::MonitorService実装
  - [ ] 2.3.1 基本構造作成
  - [ ] 2.3.2 check_error_rateメソッド実装
  - [ ] 2.3.3 check_traffic_anomalyメソッド実装
  - [ ] 2.3.4 count_requestsメソッド実装
  - [ ] 2.3.5 count_errorsメソッド実装
  - [ ] 2.3.6 alert_high_error_rateメソッド実装
  - [ ] 2.3.7 alert_traffic_spikeメソッド実装

---

### 3. Internal API実装

- [ ] 3.1 Api::Internal::SecurityController作成
  - [ ] 3.1.1 コントローラーファイル作成
  - [ ] 3.1.2 authenticate_internal_apiメソッド実装
  - [ ] 3.1.3 brakemanアクション実装
  - [ ] 3.1.4 bundler_auditアクション実装
  - [ ] 3.1.5 エラーハンドリング実装

- [ ] 3.2 ルーティング設定
  - [ ] 3.2.1 config/routes.rbに追加
  - [ ] 3.2.2 namespace :api, :internal設定
  - [ ] 3.2.3 POST /api/internal/security/brakeman
  - [ ] 3.2.4 POST /api/internal/security/bundler-audit

---

### 4. GitHub Actions ワークフロー実装

- [ ] 4.1 security-audit.ymlファイル作成
  - [ ] 4.1.1 .github/workflows/security-audit.yml作成
  - [ ] 4.1.2 トリガー設定（schedule, pull_request, push）
  - [ ] 4.1.3 brakemanジョブ実装
  - [ ] 4.1.4 bundler-auditジョブ実装
  - [ ] 4.1.5 アーティファクトアップロード設定
  - [ ] 4.1.6 通知設定（失敗時）

- [ ] 4.2 GitHub Secrets設定
  - [ ] 4.2.1 RAILS_WEBHOOK_URL設定
  - [ ] 4.2.2 INTERNAL_API_TOKEN設定
  - [ ] 4.2.3 環境変数確認

- [ ] 4.3 ワークフロー動作確認
  - [ ] 4.3.1 手動実行テスト（workflow_dispatch）
  - [ ] 4.3.2 プルリクエストトリガーテスト
  - [ ] 4.3.3 スケジュール実行確認（翌日）

---

### 5. Dependabot設定

- [ ] 5.1 dependabot.yml作成
  - [ ] 5.1.1 .github/dependabot.yml作成
  - [ ] 5.1.2 bundler設定
  - [ ] 5.1.3 npm設定
  - [ ] 5.1.4 チェック頻度設定（daily）
  - [ ] 5.1.5 ラベル設定

- [ ] 5.2 自動マージ設定
  - [ ] 5.2.1 GitHub Actions自動マージワークフロー作成
  - [ ] 5.2.2 条件設定（パッチバージョン、テスト成功）
  - [ ] 5.2.3 動作確認

---

### 6. Mailer拡張

- [ ] 6.1 SecurityMailer拡張
  - [ ] 6.1.1 security_alertメソッド追加
  - [ ] 6.1.2 high_error_rate_alertメソッド追加
  - [ ] 6.1.3 traffic_spike_alertメソッド追加

- [ ] 6.2 メールテンプレート作成
  - [ ] 6.2.1 security_alert.html.erb作成
  - [ ] 6.2.2 high_error_rate_alert.html.erb作成
  - [ ] 6.2.3 traffic_spike_alert.html.erb作成
  - [ ] 6.2.4 レスポンシブデザイン対応

---

### 7. 管理画面実装

- [ ] 7.1 SecurityScansコントローラー作成
  - [ ] 7.1.1 Admin::SecurityScansController作成
  - [ ] 7.1.2 indexアクション実装（一覧）
  - [ ] 7.1.3 showアクション実装（詳細）
  - [ ] 7.1.4 ページネーション実装

- [ ] 7.2 SecurityReportsコントローラー作成
  - [ ] 7.2.1 Admin::SecurityReportsController作成
  - [ ] 7.2.2 indexアクション実装（一覧）
  - [ ] 7.2.3 showアクション実装（詳細）
  - [ ] 7.2.4 downloadアクション実装（PDF）

- [ ] 7.3 ビュー作成
  - [ ] 7.3.1 security_scans/index.html.erb作成
  - [ ] 7.3.2 security_scans/show.html.erb作成
  - [ ] 7.3.3 security_reports/index.html.erb作成
  - [ ] 7.3.4 security_reports/show.html.erb作成
  - [ ] 7.3.5 Chart.js統合（グラフ表示）

- [ ] 7.4 ナビゲーション追加
  - [ ] 7.4.1 管理画面メニューに「セキュリティ」追加
  - [ ] 7.4.2 サブメニュー追加（スキャン、レポート）

---

### 8. Sidekiq-cron設定

- [ ] 8.1 週次レポートジョブ作成
  - [ ] 8.1.1 Security::WeeklyReportJob作成
  - [ ] 8.1.2 performメソッド実装
  - [ ] 8.1.3 エラーハンドリング実装

- [ ] 8.2 recurring.yml設定
  - [ ] 8.2.1 weekly_security_report設定追加
  - [ ] 8.2.2 cron設定（毎週月曜日午前10時）
  - [ ] 8.2.3 動作確認

---

### 9. テスト実装

- [ ] 9.1 モデルテスト
  - [ ] 9.1.1 SecurityScanモデルテスト（5件）
  - [ ] 9.1.2 Vulnerabilityモデルテスト（5件）
  - [ ] 9.1.3 SecurityReportモデルテスト（3件）

- [ ] 9.2 Serviceテスト
  - [ ] 9.2.1 Security::ScannerServiceテスト（8件）
  - [ ] 9.2.2 Security::ReporterServiceテスト（5件）
  - [ ] 9.2.3 Security::MonitorServiceテスト（4件）

- [ ] 9.3 コントローラーテスト
  - [ ] 9.3.1 Api::Internal::SecurityControllerテスト（6件）
  - [ ] 9.3.2 Admin::SecurityScansControllerテスト（4件）
  - [ ] 9.3.3 Admin::SecurityReportsControllerテスト（4件）

- [ ] 9.4 Mailerテスト
  - [ ] 9.4.1 SecurityMailerテスト（3件）

- [ ] 9.5 Jobテスト
  - [ ] 9.5.1 Security::WeeklyReportJobテスト（2件）

- [ ] 9.6 統合テスト
  - [ ] 9.6.1 スキャン→通知フローテスト
  - [ ] 9.6.2 レポート生成フローテスト

- [ ] 9.7 テスト実行・確認
  - [ ] 9.7.1 全テスト実行（bundle exec rspec）
  - [ ] 9.7.2 テストカバレッジ確認（85%以上）
  - [ ] 9.7.3 失敗テスト修正

---

## 📊 進捗トラッキング

### タスク完了状況

| カテゴリ | 総タスク数 | 完了 | 進捗率 |
|---------|----------|------|--------|
| 1. データベース | 14 | 0 | 0% |
| 2. Service | 23 | 0 | 0% |
| 3. Internal API | 7 | 0 | 0% |
| 4. GitHub Actions | 9 | 0 | 0% |
| 5. Dependabot | 7 | 0 | 0% |
| 6. Mailer | 7 | 0 | 0% |
| 7. 管理画面 | 13 | 0 | 0% |
| 8. Sidekiq-cron | 5 | 0 | 0% |
| 9. テスト | 44 | 0 | 0% |
| **合計** | **129** | **0** | **0%** |

---

## 🎯 マイルストーン

### Day 1（2026-02-16）
- [ ] データベース設計・マイグレーション完了
- [ ] モデル実装完了
- [ ] マイグレーション実行確認

### Day 2（2026-02-17）
- [ ] Serviceクラス実装完了
- [ ] Internal API実装完了
- [ ] 基本的な動作確認

### Day 3（2026-02-18）
- [ ] GitHub Actions ワークフロー実装完了
- [ ] Dependabot設定完了
- [ ] ワークフロー動作確認

### Day 4（2026-02-19）
- [ ] Mailer拡張完了
- [ ] 管理画面実装完了
- [ ] Sidekiq-cron設定完了

### Day 5（2026-02-20）
- [ ] テスト実装完了
- [ ] 全テスト成功確認
- [ ] ドキュメント作成
- [ ] Phase 7.4完了

---

## 📝 実装メモ

### 優先順位
1. **高**: データベース、Service、Internal API、GitHub Actions
2. **中**: Dependabot、Mailer、管理画面
3. **低**: Sidekiq-cron（週次レポートは後回し可）

### 依存関係
- Internal APIはServiceクラスに依存
- GitHub ActionsはInternal APIに依存
- 管理画面はモデル・Serviceに依存
- テストは全実装完了後

### 注意事項
- INTERNAL_API_TOKENは強力なトークンを生成（32文字以上）
- GitHub Secretsに機密情報を保存
- 本番環境でのテストは慎重に実施
- スキャン結果に機密情報が含まれないよう注意

---

## 🔄 Phase 7.8（通知機能）との統合

### 既存機能の活用
- SecurityMailer（Phase 7.8で実装済み）
  - brakeman_issues
  - bundler_audit_issues
  - weekly_report
- SlackNotifier（Phase 7.8で実装済み）
  - notify_security_issue

### Phase 7.4で追加
- SecurityMailer拡張
  - security_alert
  - high_error_rate_alert
  - traffic_spike_alert

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-02-03  
**🔄 バージョン**: v1.0  
**📋 ステータス**: 未着手
