# Phase 7.4: セキュリティ監査自動化 - 設計書

## 📅 作成日: 2026-02-03
## 🎯 Phase: 7.4
## ⚡️ 優先度: 中
## 📊 ステータス: 設計完了

---

## 📋 目次

1. [アーキテクチャ概要](#アーキテクチャ概要)
2. [コンポーネント設計](#コンポーネント設計)
3. [データモデル](#データモデル)
4. [API設計](#api設計)
5. [GitHub Actions設計](#github-actions設計)
6. [通知設計](#通知設計)
7. [セキュリティ設計](#セキュリティ設計)
8. [テスト設計](#テスト設計)

---

## 🏗️ アーキテクチャ概要

### システム構成図

```
┌─────────────────────────────────────────────────────────────┐
│                      GitHub Actions                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Brakeman    │  │bundler-audit │  │  Scheduled   │      │
│  │   Scan       │  │    Scan      │  │   Reports    │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │              │
│         └──────────────────┴──────────────────┘              │
│                            │                                 │
└────────────────────────────┼─────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                    Rails Application                         │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              Security Audit Services                  │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐     │   │
│  │  │  Scanner   │  │  Reporter  │  │  Monitor   │     │   │
│  │  │  Service   │  │  Service   │  │  Service   │     │   │
│  │  └────────────┘  └────────────┘  └────────────┘     │   │
│  └──────────────────────────────────────────────────────┘   │
│                            │                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                 Notification Layer                    │   │
│  │  ┌────────────┐  ┌────────────┐                      │   │
│  │  │ Security   │  │   Slack    │                      │   │
│  │  │  Mailer    │  │  Notifier  │                      │   │
│  │  └────────────┘  └────────────┘                      │   │
│  └──────────────────────────────────────────────────────┘   │
│                            │                                 │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   Data Layer                          │   │
│  │  ┌────────────┐  ┌────────────┐                      │   │
│  │  │ Security   │  │ Security   │                      │   │
│  │  │   Scan     │  │   Report   │                      │   │
│  │  └────────────┘  └────────────┘                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────┐
│                      External Services                       │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐            │
│  │  AWS SES   │  │   Slack    │  │  GitHub    │            │
│  │   (Mail)   │  │  (Webhook) │  │   (API)    │            │
│  └────────────┘  └────────────┘  └────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

### データフロー

```
1. GitHub Actions (Scheduled)
   ↓
2. Brakeman/bundler-audit実行
   ↓
3. 結果をJSON形式で保存
   ↓
4. Rails API経由でデータベースに保存
   ↓
5. 脆弱性検知時に通知送信
   ↓
6. 週次レポート生成（Sidekiq-cron）
   ↓
7. レポート送信・管理画面表示
```

---

## 🧩 コンポーネント設計

### 1. GitHub Actions ワークフロー

#### 1.1 security-audit.yml

```yaml
name: Security Audit

on:
  schedule:
    # 毎日午前9時JST（午前0時UTC）
    - cron: '0 0 * * *'
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]
  workflow_dispatch:

jobs:
  brakeman:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.7
          bundler-cache: true
      - name: Run Brakeman
        run: |
          bundle exec brakeman -o brakeman-report.json -o brakeman-report.html
      - name: Upload Brakeman results
        uses: actions/upload-artifact@v4
        with:
          name: brakeman-results
          path: brakeman-report.*
      - name: Notify on failure
        if: failure()
        run: |
          curl -X POST ${{ secrets.RAILS_WEBHOOK_URL }}/api/internal/security/brakeman \
            -H "Authorization: Bearer ${{ secrets.INTERNAL_API_TOKEN }}" \
            -H "Content-Type: application/json" \
            -d @brakeman-report.json

  bundler-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.7
          bundler-cache: true
      - name: Update bundler-audit database
        run: bundle exec bundler-audit update
      - name: Run bundler-audit
        run: |
          bundle exec bundler-audit check --format json > bundler-audit-report.json || true
      - name: Upload bundler-audit results
        uses: actions/upload-artifact@v4
        with:
          name: bundler-audit-results
          path: bundler-audit-report.json
      - name: Notify on vulnerabilities
        run: |
          if [ -s bundler-audit-report.json ]; then
            curl -X POST ${{ secrets.RAILS_WEBHOOK_URL }}/api/internal/security/bundler-audit \
              -H "Authorization: Bearer ${{ secrets.INTERNAL_API_TOKEN }}" \
              -H "Content-Type: application/json" \
              -d @bundler-audit-report.json
          fi
```

### 2. Serviceクラス

#### 2.1 Security::ScannerService

```ruby
# app/services/security/scanner_service.rb
module Security
  class ScannerService
    def initialize(scan_type:, results:)
      @scan_type = scan_type
      @results = results
    end

    def process
      scan = create_scan
      parse_results(scan)
      notify_if_vulnerabilities(scan)
      scan
    end

    private

    def create_scan
      SecurityScan.create!(
        scan_type: @scan_type,
        status: 'completed',
        raw_results: @results,
        scanned_at: Time.current
      )
    end

    def parse_results(scan)
      case @scan_type
      when 'brakeman'
        parse_brakeman_results(scan)
      when 'bundler_audit'
        parse_bundler_audit_results(scan)
      end
    end

    def parse_brakeman_results(scan)
      warnings = @results['warnings'] || []
      
      warnings.each do |warning|
        scan.vulnerabilities.create!(
          severity: map_brakeman_severity(warning['confidence']),
          title: warning['warning_type'],
          description: warning['message'],
          file_path: warning['file'],
          line_number: warning['line'],
          cve_id: nil,
          fixed: false
        )
      end
    end

    def parse_bundler_audit_results(scan)
      results = @results['results'] || []
      
      results.each do |result|
        result['advisories'].each do |advisory|
          scan.vulnerabilities.create!(
            severity: map_bundler_audit_severity(advisory['criticality']),
            title: advisory['title'],
            description: advisory['description'],
            gem_name: result['gem']['name'],
            gem_version: result['gem']['version'],
            cve_id: advisory['cve'],
            patched_versions: advisory['patched_versions'].join(', '),
            fixed: false
          )
        end
      end
    end

    def notify_if_vulnerabilities(scan)
      return if scan.vulnerabilities.empty?

      high_severity = scan.vulnerabilities.where(severity: ['critical', 'high'])
      
      if high_severity.any?
        SecurityMailer.security_alert(scan).deliver_later
        SlackNotifier.notify_security_issue(
          title: "#{@scan_type.titleize} Scan: #{high_severity.count} High/Critical Issues",
          details: format_vulnerabilities(high_severity)
        )
      end
    end

    def map_brakeman_severity(confidence)
      case confidence
      when 'High' then 'high'
      when 'Medium' then 'medium'
      when 'Weak' then 'low'
      else 'info'
      end
    end

    def map_bundler_audit_severity(criticality)
      case criticality
      when 'Critical' then 'critical'
      when 'High' then 'high'
      when 'Medium' then 'medium'
      when 'Low' then 'low'
      else 'info'
      end
    end

    def format_vulnerabilities(vulnerabilities)
      vulnerabilities.map do |v|
        "• #{v.title} (#{v.severity.upcase})\n  #{v.description.truncate(100)}"
      end.join("\n\n")
    end
  end
end
```

#### 2.2 Security::ReporterService

```ruby
# app/services/security/reporter_service.rb
module Security
  class ReporterService
    def initialize(start_date: 1.week.ago, end_date: Time.current)
      @start_date = start_date
      @end_date = end_date
    end

    def generate_weekly_report
      report = SecurityReport.create!(
        report_type: 'weekly',
        period_start: @start_date,
        period_end: @end_date,
        generated_at: Time.current
      )

      collect_scan_data(report)
      collect_vulnerability_data(report)
      collect_incident_data(report)
      
      report.update!(status: 'completed')
      
      send_report(report)
      
      report
    end

    private

    def collect_scan_data(report)
      scans = SecurityScan.where(scanned_at: @start_date..@end_date)
      
      report.data['scans'] = {
        total: scans.count,
        brakeman: scans.where(scan_type: 'brakeman').count,
        bundler_audit: scans.where(scan_type: 'bundler_audit').count
      }
    end

    def collect_vulnerability_data(report)
      vulnerabilities = Vulnerability.where(created_at: @start_date..@end_date)
      
      report.data['vulnerabilities'] = {
        total: vulnerabilities.count,
        new: vulnerabilities.where(fixed: false).count,
        fixed: vulnerabilities.where(fixed: true).count,
        by_severity: {
          critical: vulnerabilities.where(severity: 'critical').count,
          high: vulnerabilities.where(severity: 'high').count,
          medium: vulnerabilities.where(severity: 'medium').count,
          low: vulnerabilities.where(severity: 'low').count
        }
      }
    end

    def collect_incident_data(report)
      # SecurityLoggerからのデータ収集
      report.data['incidents'] = {
        failed_logins: count_failed_logins,
        blocked_ips: count_blocked_ips,
        csrf_errors: count_csrf_errors
      }
    end

    def send_report(report)
      SecurityMailer.weekly_report(report).deliver_later
    end

    def count_failed_logins
      # SecurityLoggerのログから集計
      # 実装は既存のSecurityLoggerに依存
      0
    end

    def count_blocked_ips
      # Rack::Attackのログから集計
      0
    end

    def count_csrf_errors
      # Railsログから集計
      0
    end
  end
end
```

#### 2.3 Security::MonitorService

```ruby
# app/services/security/monitor_service.rb
module Security
  class MonitorService
    THRESHOLDS = {
      error_rate: 0.05, # 5%
      errors_per_minute: 10,
      requests_per_minute: 1000,
      requests_per_ip: 100
    }.freeze

    def check_error_rate
      total_requests = count_requests(10.minutes.ago)
      error_requests = count_errors(10.minutes.ago)
      
      return if total_requests.zero?
      
      error_rate = error_requests.to_f / total_requests
      
      if error_rate > THRESHOLDS[:error_rate]
        alert_high_error_rate(error_rate, total_requests, error_requests)
      end
    end

    def check_traffic_anomaly
      current_rpm = count_requests(1.minute.ago)
      
      if current_rpm > THRESHOLDS[:requests_per_minute]
        alert_traffic_spike(current_rpm)
      end
    end

    private

    def count_requests(since)
      # Railsログまたはメトリクスから集計
      # 実装は環境に依存
      0
    end

    def count_errors(since)
      # Railsログから500エラーを集計
      0
    end

    def alert_high_error_rate(rate, total, errors)
      SecurityMailer.high_error_rate_alert(
        rate: rate,
        total_requests: total,
        error_requests: errors
      ).deliver_now

      SlackNotifier.notify_security_issue(
        title: "High Error Rate Detected",
        details: "Error rate: #{(rate * 100).round(2)}% (#{errors}/#{total} requests)"
      )
    end

    def alert_traffic_spike(rpm)
      SecurityMailer.traffic_spike_alert(
        requests_per_minute: rpm
      ).deliver_now

      SlackNotifier.notify_security_issue(
        title: "Traffic Spike Detected",
        details: "#{rpm} requests/minute (threshold: #{THRESHOLDS[:requests_per_minute]})"
      )
    end
  end
end
```

---

## 📊 データモデル

### 1. SecurityScan

```ruby
# app/models/security_scan.rb
class SecurityScan < ApplicationRecord
  has_many :vulnerabilities, dependent: :destroy
  
  enum scan_type: { brakeman: 0, bundler_audit: 1 }
  enum status: { pending: 0, running: 1, completed: 2, failed: 3 }
  
  validates :scan_type, presence: true
  validates :status, presence: true
  validates :scanned_at, presence: true
  
  scope :recent, -> { order(scanned_at: :desc) }
  scope :with_vulnerabilities, -> { joins(:vulnerabilities).distinct }
  
  def high_severity_count
    vulnerabilities.where(severity: ['critical', 'high']).count
  end
  
  def summary
    {
      total: vulnerabilities.count,
      critical: vulnerabilities.where(severity: 'critical').count,
      high: vulnerabilities.where(severity: 'high').count,
      medium: vulnerabilities.where(severity: 'medium').count,
      low: vulnerabilities.where(severity: 'low').count
    }
  end
end
```

**マイグレーション**:
```ruby
class CreateSecurityScans < ActiveRecord::Migration[8.0]
  def change
    create_table :security_scans do |t|
      t.integer :scan_type, null: false
      t.integer :status, null: false, default: 0
      t.jsonb :raw_results
      t.datetime :scanned_at, null: false
      t.text :error_message
      
      t.timestamps
    end
    
    add_index :security_scans, :scan_type
    add_index :security_scans, :status
    add_index :security_scans, :scanned_at
  end
end
```

### 2. Vulnerability

```ruby
# app/models/vulnerability.rb
class Vulnerability < ApplicationRecord
  belongs_to :security_scan
  
  enum severity: { info: 0, low: 1, medium: 2, high: 3, critical: 4 }
  
  validates :severity, presence: true
  validates :title, presence: true
  validates :description, presence: true
  
  scope :unfixed, -> { where(fixed: false) }
  scope :by_severity, -> { order(severity: :desc) }
  
  def mark_as_fixed!
    update!(fixed: true, fixed_at: Time.current)
  end
end
```

**マイグレーション**:
```ruby
class CreateVulnerabilities < ActiveRecord::Migration[8.0]
  def change
    create_table :vulnerabilities do |t|
      t.references :security_scan, null: false, foreign_key: true
      t.integer :severity, null: false
      t.string :title, null: false
      t.text :description, null: false
      t.string :file_path
      t.integer :line_number
      t.string :gem_name
      t.string :gem_version
      t.string :cve_id
      t.string :patched_versions
      t.boolean :fixed, default: false
      t.datetime :fixed_at
      
      t.timestamps
    end
    
    add_index :vulnerabilities, :severity
    add_index :vulnerabilities, :fixed
    add_index :vulnerabilities, :cve_id
  end
end
```

### 3. SecurityReport

```ruby
# app/models/security_report.rb
class SecurityReport < ApplicationRecord
  enum report_type: { weekly: 0, monthly: 1, custom: 2 }
  enum status: { pending: 0, generating: 1, completed: 2, failed: 3 }
  
  validates :report_type, presence: true
  validates :period_start, presence: true
  validates :period_end, presence: true
  
  scope :recent, -> { order(generated_at: :desc) }
  
  def pdf_filename
    "security-report-#{period_start.to_date}-#{period_end.to_date}.pdf"
  end
end
```

**マイグレーション**:
```ruby
class CreateSecurityReports < ActiveRecord::Migration[8.0]
  def change
    create_table :security_reports do |t|
      t.integer :report_type, null: false
      t.integer :status, null: false, default: 0
      t.datetime :period_start, null: false
      t.datetime :period_end, null: false
      t.jsonb :data, default: {}
      t.datetime :generated_at
      
      t.timestamps
    end
    
    add_index :security_reports, :report_type
    add_index :security_reports, :status
    add_index :security_reports, :generated_at
  end
end
```

---

## 🔌 API設計

### Internal API（GitHub Actions用）

#### POST /api/internal/security/brakeman

**リクエスト**:
```json
{
  "warnings": [
    {
      "warning_type": "SQL Injection",
      "confidence": "High",
      "message": "Possible SQL injection",
      "file": "app/models/user.rb",
      "line": 42
    }
  ]
}
```

**レスポンス**:
```json
{
  "success": true,
  "scan_id": 123,
  "vulnerabilities_count": 1
}
```

#### POST /api/internal/security/bundler-audit

**リクエスト**:
```json
{
  "results": [
    {
      "gem": {
        "name": "rails",
        "version": "8.0.0"
      },
      "advisories": [
        {
          "title": "XSS vulnerability",
          "cve": "CVE-2024-12345",
          "criticality": "High",
          "description": "...",
          "patched_versions": [">= 8.0.1"]
        }
      ]
    }
  ]
}
```

**レスポンス**:
```json
{
  "success": true,
  "scan_id": 124,
  "vulnerabilities_count": 1
}
```

---

## 🔔 通知設計

### Phase 7.8（通知機能）との統合

#### SecurityMailer拡張

```ruby
# app/mailers/security_mailer.rb
class SecurityMailer < ApplicationMailer
  # 既存メソッド（Phase 7.8で実装済み）
  # - brakeman_issues
  # - bundler_audit_issues
  # - weekly_report
  
  # Phase 7.4で追加
  def security_alert(scan)
    @scan = scan
    @vulnerabilities = scan.vulnerabilities.where(severity: ['critical', 'high'])
    
    mail(
      to: ENV['SECURITY_AUDIT_EMAIL'],
      subject: "[SECURITY ALERT] #{scan.scan_type.titleize}: #{@vulnerabilities.count} High/Critical Issues"
    )
  end
  
  def high_error_rate_alert(rate:, total_requests:, error_requests:)
    @rate = rate
    @total_requests = total_requests
    @error_requests = error_requests
    
    mail(
      to: ENV['ADMIN_EMAIL'],
      subject: "[ALERT] High Error Rate Detected: #{(rate * 100).round(2)}%"
    )
  end
  
  def traffic_spike_alert(requests_per_minute:)
    @requests_per_minute = requests_per_minute
    
    mail(
      to: ENV['ADMIN_EMAIL'],
      subject: "[ALERT] Traffic Spike Detected: #{requests_per_minute} req/min"
    )
  end
end
```

#### SlackNotifier拡張

```ruby
# app/services/slack_notifier.rb（既存）
class SlackNotifier
  # 既存メソッド（Phase 7.8で実装済み）
  # - notify_security_issue
  
  # Phase 7.4では既存メソッドを活用
end
```

---

## 🔒 セキュリティ設計

### 1. API認証

```ruby
# app/controllers/api/internal/security_controller.rb
module Api
  module Internal
    class SecurityController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_internal_api
      
      private
      
      def authenticate_internal_api
        token = request.headers['Authorization']&.remove('Bearer ')
        
        unless ActiveSupport::SecurityUtils.secure_compare(
          token.to_s,
          ENV['INTERNAL_API_TOKEN'].to_s
        )
          render json: { error: 'Unauthorized' }, status: :unauthorized
        end
      end
    end
  end
end
```

### 2. 機密情報の除外

```ruby
# app/services/security/scanner_service.rb
def sanitize_results(results)
  # パスワード、トークン等の除外
  results.deep_dup.tap do |sanitized|
    sanitized.deep_transform_values! do |value|
      if value.is_a?(String) && sensitive_pattern?(value)
        '[REDACTED]'
      else
        value
      end
    end
  end
end

def sensitive_pattern?(value)
  value.match?(/password|token|secret|key/i)
end
```

---

## 🧪 テスト設計

### 1. RSpecテスト

#### 1.1 Security::ScannerService

```ruby
# spec/services/security/scanner_service_spec.rb
RSpec.describe Security::ScannerService do
  describe '#process' do
    context 'with brakeman results' do
      let(:results) do
        {
          'warnings' => [
            {
              'warning_type' => 'SQL Injection',
              'confidence' => 'High',
              'message' => 'Possible SQL injection',
              'file' => 'app/models/user.rb',
              'line' => 42
            }
          ]
        }
      end
      
      it 'creates a security scan' do
        expect {
          described_class.new(scan_type: 'brakeman', results: results).process
        }.to change(SecurityScan, :count).by(1)
      end
      
      it 'creates vulnerabilities' do
        expect {
          described_class.new(scan_type: 'brakeman', results: results).process
        }.to change(Vulnerability, :count).by(1)
      end
      
      it 'sends notification for high severity' do
        expect(SecurityMailer).to receive(:security_alert).and_call_original
        described_class.new(scan_type: 'brakeman', results: results).process
      end
    end
  end
end
```

#### 1.2 Security::ReporterService

```ruby
# spec/services/security/reporter_service_spec.rb
RSpec.describe Security::ReporterService do
  describe '#generate_weekly_report' do
    it 'creates a security report' do
      expect {
        described_class.new.generate_weekly_report
      }.to change(SecurityReport, :count).by(1)
    end
    
    it 'sends report email' do
      expect(SecurityMailer).to receive(:weekly_report).and_call_original
      described_class.new.generate_weekly_report
    end
  end
end
```

### 2. GitHub Actions テスト

```yaml
# .github/workflows/test-security-audit.yml
name: Test Security Audit

on:
  pull_request:
    paths:
      - '.github/workflows/security-audit.yml'

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: 3.4.7
          bundler-cache: true
      - name: Test Brakeman
        run: bundle exec brakeman --version
      - name: Test bundler-audit
        run: bundle exec bundler-audit --version
```

---

## 📝 実装例

### Sidekiq-cron設定

```yaml
# config/recurring.yml
weekly_security_report:
  cron: "0 10 * * 1" # 毎週月曜日午前10時JST
  class: "Security::WeeklyReportJob"
  queue: default
  description: "Generate and send weekly security report"
```

### Job実装

```ruby
# app/jobs/security/weekly_report_job.rb
module Security
  class WeeklyReportJob < ApplicationJob
    queue_as :default
    
    def perform
      Security::ReporterService.new.generate_weekly_report
    end
  end
end
```

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-02-03  
**🔄 バージョン**: v1.0  
**📋 ステータス**: 設計完了
