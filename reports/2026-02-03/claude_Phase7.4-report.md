# 作業報告 - Phase 7.4 セキュリティ監査自動化

## 基本情報
- **日時**: 2026-02-03
- **ブランチ**: main
- **最新コミット**: 1463a4f 管理画面操作のRack::Attackブロックを緩和

## 完了タスク
- [x] Phase 7.4 データベース設計・マイグレーション
- [x] Phase 7.4 Serviceクラス実装
- [x] Phase 7.4 Internal API実装
- [x] Phase 7.4 GitHub Actions実装
- [x] Phase 7.4 Mailer拡張・管理画面実装
- [x] Phase 7.4 テスト実装

## 実装内容

### 変更ファイル

**新規作成ファイル（40ファイル）**

データベース・モデル:
- `db/migrate/20260203072452_create_security_scans.rb`
- `db/migrate/20260203072652_create_vulnerabilities.rb`
- `db/migrate/20260203072657_create_security_reports.rb`
- `app/models/security_scan.rb`
- `app/models/vulnerability.rb`
- `app/models/security_report.rb`

サービスクラス:
- `app/services/security/scanner_service.rb`
- `app/services/security/reporter_service.rb`
- `app/services/security/monitor_service.rb`

ジョブ:
- `app/jobs/security/weekly_report_job.rb`

コントローラー:
- `app/controllers/api/internal/security_controller.rb`
- `app/controllers/admin/security_scans_controller.rb`
- `app/controllers/admin/security_reports_controller.rb`

ビュー:
- `app/views/admin/security_scans/index.html.erb`
- `app/views/admin/security_scans/show.html.erb`
- `app/views/admin/security_reports/index.html.erb`
- `app/views/admin/security_reports/show.html.erb`
- `app/views/security_mailer/security_alert.html.erb`
- `app/views/security_mailer/security_alert.text.erb`
- `app/views/security_mailer/high_error_rate_alert.html.erb`
- `app/views/security_mailer/high_error_rate_alert.text.erb`
- `app/views/security_mailer/traffic_spike_alert.html.erb`
- `app/views/security_mailer/traffic_spike_alert.text.erb`

GitHub Actions:
- `.github/workflows/security-audit.yml`
- `.github/workflows/dependabot-auto-merge.yml`

テスト:
- `spec/models/security_scan_spec.rb`
- `spec/models/vulnerability_spec.rb`
- `spec/models/security_report_spec.rb`
- `spec/factories/security_scans.rb`
- `spec/factories/vulnerabilities.rb`
- `spec/factories/security_reports.rb`
- `spec/services/security/scanner_service_spec.rb`
- `spec/services/security/reporter_service_spec.rb`
- `spec/services/security/monitor_service_spec.rb`
- `spec/requests/api/internal/security_spec.rb`
- `spec/requests/admin/security_scans_spec.rb`
- `spec/requests/admin/security_reports_spec.rb`
- `spec/jobs/security/weekly_report_job_spec.rb`

**変更ファイル（8ファイル）**
- `.github/dependabot.yml` - 日次チェック、グループ化更新設定追加
- `app/mailers/security_mailer.rb` - security_alert, high_error_rate_alert, traffic_spike_alert メソッド追加
- `app/views/admin/shared/_navigation.html.erb` - セキュリティスキャン・レポートへのナビゲーション追加
- `config/recurring.yml` - 週次セキュリティレポートジョブ追加
- `config/routes.rb` - Internal APIルート、管理画面ルート追加
- `db/schema.rb` - 新テーブル反映
- `spec/mailers/security_mailer_spec.rb` - 新メソッドのテスト追加

### 技術的な判断・決定事項

1. **Internal API認証方式**: Bearer Token認証を採用。`INTERNAL_API_TOKEN`環境変数で管理し、`ActiveSupport::SecurityUtils.secure_compare`で安全に比較

2. **脆弱性の重大度マッピング**:
   - Brakeman: High → critical, Medium → high, Weak → medium, その他 → low
   - Bundler-audit: High → critical, Medium → high, Low → medium

3. **週次レポートスケジュール**: SolidQueueのrecurring.ymlで毎週月曜10:00（Asia/Tokyo）に設定

4. **GitHub Actionsの実行頻度**: 毎日深夜3時にセキュリティスキャン実行。PRトリガーなし（CI負荷軽減）

5. **Dependabot自動マージ**: パッチバージョン更新のみ自動マージ。マイナー・メジャーは手動確認

## 発生した課題と解決策

### 1. テスト環境でのホスト認証エラー
**問題**: リクエストスペックで「Blocked hosts: www.example.com」エラーが発生

**原因**: Rails 8のHost Authorization機能がテスト環境でも有効化されていた

**解決策**: 各リクエストスペックのbeforeブロックに`host! "localhost"`を追加

### 2. Devise認証スコープの不一致
**問題**: `sign_in admin_user`だけでは403エラーが発生

**解決策**: `sign_in admin_user, scope: :admin_user`でスコープを明示的に指定

### 3. freeze_timeヘルパーの欠如
**問題**: `freeze_time`メソッドが未定義でテスト失敗

**解決策**: `be_within(1.second).of(Time.current)`マッチャーで時刻の近似比較に変更

## テスト結果

```
78 examples, 0 failures
```

- モデルテスト: 24テスト
- サービステスト: 20テスト
- リクエストテスト: 17テスト
- メーラーテスト: 14テスト
- ジョブテスト: 3テスト

## 次回申し送り事項

1. **本番環境設定**: `INTERNAL_API_TOKEN`環境変数の設定が必要

2. **GitHub Secretsの設定**: `INTERNAL_API_TOKEN`と`INTERNAL_API_URL`をリポジトリシークレットに追加

3. **Slack通知の有効化**: 本番環境で`SlackNotifier.enabled?`がtrueになるようWebhook URLを設定

4. **初回セキュリティスキャンの実行**: GitHub Actionsを手動トリガーして動作確認

5. **管理画面からの確認**: `/admin.../security_scans`と`/admin.../security_reports`にアクセスして画面表示を確認

6. **未コミットの変更**: 今回の実装はまだコミットされていないため、コミットとプッシュが必要
