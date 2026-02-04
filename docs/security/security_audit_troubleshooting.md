# セキュリティ監査トラブルシューティング

## GitHub Actions が失敗する

- **症状**: `Security Audit` ワークフローが失敗
- **確認**:
  - `bundle exec brakeman` 実行ログ
  - `bundle exec bundler-audit` 実行ログ
  - `INTERNAL_API_TOKEN` / `RAILS_WEBHOOK_URL` が GitHub Secrets に設定済みか
- **対応**:
  - 依存関係更新（Gemfile.lock / package-lock.json）
  - 失敗アーティファクトをダウンロードして内容を確認

## 内部APIが 401 を返す

- **症状**: `POST /api/internal/security/...` が Unauthorized
- **確認**:
  - `INTERNAL_API_TOKEN` が一致しているか
  - リクエストヘッダーが `Authorization: Bearer <token>` 形式か
- **対応**:
  - GitHub Secrets と本番環境の `INTERNAL_API_TOKEN` を再設定

## スキャン結果が保存されない

- **症状**: 管理画面にスキャン結果が出ない
- **確認**:
  - アプリ側のログに `Security scan processing failed` が出ていないか
  - DB の `security_scans` / `vulnerabilities` テーブルにデータがあるか
- **対応**:
  - `Security::ScannerService` のエラー内容を確認
  - DB 接続やマイグレーションの適用状況を確認

## 週次レポートが生成されない

- **症状**: `SecurityReport` が作成されない
- **確認**:
  - `Security::WeeklyReportJob` がスケジュールに登録されているか
  - Sidekiq / Solid Queue が稼働しているか
- **対応**:
  - `rails runner "Security::ReporterService.new.generate_weekly_report"` で手動実行
  - `config/recurring.yml` の cron 設定を確認

## Chart.js が表示されない

- **症状**: 管理画面でグラフが表示されない
- **確認**:
  - `app/javascript/application.js` で Chart.js が読み込まれているか
  - ブラウザコンソールにエラーがないか
- **対応**:
  - JS ビルドを再実行
  - `security-report-charts` コントローラーのデータ属性を確認
