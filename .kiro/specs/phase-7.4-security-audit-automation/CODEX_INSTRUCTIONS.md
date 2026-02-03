# Phase 7.4: セキュリティ監査自動化 - Codex検証指示書

## 📅 作成日: 2026-02-03
## 🎯 Phase: 7.4
## 🔍 検証担当: Codex
## 📊 ステータス: 検証待ち

---

## 🎯 検証概要

Phase 7.4の実装完了後、セキュリティ、機能、パフォーマンスの観点から包括的な検証を実施してください。

### 検証の目的
1. **セキュリティ検証**: 脆弱性の有無、セキュリティベストプラクティスの遵守
2. **機能検証**: 要件定義書との照合、受け入れ基準の確認
3. **品質検証**: テストカバレッジ、コード品質、パフォーマンス

---

## 📚 必読ドキュメント

検証前に以下のドキュメントを必ず確認してください：

1. **要件定義書**: `requirements.md`
   - ユーザーストーリー
   - 機能要件
   - 受け入れ基準

2. **設計書**: `design.md`
   - アーキテクチャ
   - コンポーネント設計
   - セキュリティ設計

3. **タスクリスト**: `tasks.md`
   - 実装タスク一覧
   - 完了状況

4. **Claude Code実装指示書**: `CLAUDE_CODE_INSTRUCTIONS.md`
   - 実装内容
   - セキュリティ要件

---

## 🔒 セキュリティ検証

### 1. 静的解析

#### 1.1 Brakeman実行

```bash
bundle exec brakeman -o brakeman-report.html
```

**確認項目**:
- [ ] 警告0件
- [ ] 新規脆弱性なし
- [ ] 既存脆弱性の悪化なし

#### 1.2 bundler-audit実行

```bash
bundle exec bundler-audit update
bundle exec bundler-audit check
```

**確認項目**:
- [ ] 脆弱性0件
- [ ] 依存関係の脆弱性なし

#### 1.3 RuboCop Security実行

```bash
bundle exec rubocop --only Security
```

**確認項目**:
- [ ] 違反0件
- [ ] セキュリティベストプラクティス遵守

### 2. API認証検証

#### 2.1 INTERNAL_API_TOKEN検証

**テストケース**:
1. 正しいトークンでアクセス → 200 OK
2. 誤ったトークンでアクセス → 401 Unauthorized
3. トークンなしでアクセス → 401 Unauthorized
4. 空のトークンでアクセス → 401 Unauthorized

**実行例**:
```bash
# 正しいトークン
curl -X POST http://localhost:3000/api/internal/security/brakeman \
  -H "Authorization: Bearer ${INTERNAL_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"warnings": []}'

# 誤ったトークン
curl -X POST http://localhost:3000/api/internal/security/brakeman \
  -H "Authorization: Bearer invalid_token" \
  -H "Content-Type: application/json" \
  -d '{"warnings": []}'
```

**確認項目**:
- [ ] 認証が正しく機能する
- [ ] タイミング攻撃対策（secure_compare使用）
- [ ] エラーメッセージが適切

### 3. 機密情報の除外検証

#### 3.1 スキャン結果の確認

**確認項目**:
- [ ] パスワードが除外されている
- [ ] トークンが除外されている
- [ ] APIキーが除外されている
- [ ] 機密情報が[REDACTED]に置換されている

#### 3.2 メール通知の確認

**確認項目**:
- [ ] メール本文に機密情報が含まれない
- [ ] サマリーのみ表示
- [ ] 詳細は管理画面へのリンク

### 4. アクセス制御検証

#### 4.1 管理画面アクセス

**テストケース**:
1. 未認証ユーザー → ログイン画面へリダイレクト
2. 認証済みユーザー → アクセス可能

**確認項目**:
- [ ] 認証が必須
- [ ] 管理者のみアクセス可能
- [ ] セッション管理が適切

---

## ✅ 機能検証

### 1. 静的解析自動化

#### 1.1 GitHub Actions ワークフロー

**確認項目**:
- [ ] `.github/workflows/security-audit.yml`が存在する
- [ ] スケジュール実行が設定されている（cron）
- [ ] プルリクエストトリガーが設定されている
- [ ] Brakemanジョブが実装されている
- [ ] bundler-auditジョブが実装されている
- [ ] アーティファクトアップロードが設定されている
- [ ] 通知送信が実装されている（失敗時）

#### 1.2 ワークフロー実行テスト

**手動実行**:
```bash
# GitHub ActionsのUIから手動実行（workflow_dispatch）
```

**確認項目**:
- [ ] ワークフローが正常に実行される
- [ ] Brakemanスキャンが成功する
- [ ] bundler-auditスキャンが成功する
- [ ] アーティファクトがアップロードされる
- [ ] 脆弱性発見時に通知が送信される

### 2. Dependabot設定

#### 2.1 dependabot.yml確認

**確認項目**:
- [ ] `.github/dependabot.yml`が存在する
- [ ] bundler設定がある
- [ ] npm設定がある
- [ ] チェック頻度が日次
- [ ] ラベルが設定されている

#### 2.2 Dependabot動作確認

**確認項目**:
- [ ] 脆弱性発見時に自動PRが作成される
- [ ] PRに脆弱性の詳細が記載される
- [ ] 重大度に応じてラベルが付与される

### 3. ログ監視・アラート

#### 3.1 エラー率監視

**テストケース**:
1. 正常時 → アラートなし
2. エラー率 > 5% → アラート送信

**確認項目**:
- [ ] エラー率が正しく計算される
- [ ] 閾値を超えた場合にアラートが送信される
- [ ] メール通知が送信される
- [ ] Slack通知が送信される

#### 3.2 トラフィック異常検知

**テストケース**:
1. 正常時 → アラートなし
2. リクエスト数 > 1000/分 → アラート送信

**確認項目**:
- [ ] リクエスト数が正しく計算される
- [ ] 閾値を超えた場合にアラートが送信される

### 4. セキュリティレポート

#### 4.1 週次レポート生成

**手動実行**:
```bash
rails runner "Security::ReporterService.new.generate_weekly_report"
```

**確認項目**:
- [ ] レポートが生成される
- [ ] スキャンデータが含まれる
- [ ] 脆弱性データが含まれる
- [ ] インシデントデータが含まれる
- [ ] メール通知が送信される

#### 4.2 管理画面表示

**確認項目**:
- [ ] レポート一覧が表示される
- [ ] レポート詳細が表示される
- [ ] グラフ・チャートが表示される（Chart.js）
- [ ] PDF出力ができる

---

## 🧪 テスト検証

### 1. テスト実行

```bash
bundle exec rspec
```

**確認項目**:
- [ ] 全テスト成功
- [ ] テスト数10件以上
- [ ] テストカバレッジ85%以上

### 2. テストカバレッジ確認

```bash
COVERAGE=true bundle exec rspec
open coverage/index.html
```

**確認項目**:
- [ ] モデルテスト: 100%
- [ ] Serviceテスト: 90%以上
- [ ] コントローラーテスト: 85%以上
- [ ] 全体: 85%以上

### 3. エッジケーステスト

#### 3.1 空のスキャン結果

**テストケース**:
```ruby
Security::ScannerService.new(
  scan_type: 'brakeman',
  results: { 'warnings' => [] }
).process
```

**確認項目**:
- [ ] エラーが発生しない
- [ ] スキャンが作成される
- [ ] 脆弱性が0件
- [ ] 通知が送信されない

#### 3.2 大量の脆弱性

**テストケース**:
```ruby
warnings = 100.times.map do |i|
  {
    'warning_type' => "Warning #{i}",
    'confidence' => 'High',
    'message' => "Message #{i}",
    'file' => 'app/models/user.rb',
    'line' => i
  }
end

Security::ScannerService.new(
  scan_type: 'brakeman',
  results: { 'warnings' => warnings }
).process
```

**確認項目**:
- [ ] パフォーマンスが許容範囲内（10秒以内）
- [ ] すべての脆弱性が保存される
- [ ] 通知が送信される

#### 3.3 不正なJSON

**テストケース**:
```bash
curl -X POST http://localhost:3000/api/internal/security/brakeman \
  -H "Authorization: Bearer ${INTERNAL_API_TOKEN}" \
  -H "Content-Type: application/json" \
  -d 'invalid json'
```

**確認項目**:
- [ ] 400 Bad Requestが返される
- [ ] エラーメッセージが適切
- [ ] ログが記録される

---

## 📊 パフォーマンス検証

### 1. スキャン実行時間

**測定方法**:
```ruby
require 'benchmark'

time = Benchmark.realtime do
  Security::ScannerService.new(
    scan_type: 'brakeman',
    results: large_results
  ).process
end

puts "Execution time: #{time} seconds"
```

**確認項目**:
- [ ] Brakemanスキャン: 5分以内
- [ ] bundler-auditスキャン: 2分以内
- [ ] 合計: 10分以内

### 2. レポート生成時間

**測定方法**:
```ruby
time = Benchmark.realtime do
  Security::ReporterService.new.generate_weekly_report
end

puts "Report generation time: #{time} seconds"
```

**確認項目**:
- [ ] レポート生成: 3分以内
- [ ] PDF出力: 30秒以内

### 3. データベースクエリ最適化

**確認項目**:
- [ ] N+1クエリなし
- [ ] インデックスが適切に使用されている
- [ ] クエリ実行時間が許容範囲内

---

## 🔍 コード品質検証

### 1. RuboCop実行

```bash
bundle exec rubocop
```

**確認項目**:
- [ ] 違反0件
- [ ] コーディング規約遵守
- [ ] 可読性が高い

### 2. コードレビュー

#### 2.1 Serviceクラス

**確認項目**:
- [ ] 単一責任の原則（SRP）遵守
- [ ] DRY原則遵守
- [ ] エラーハンドリングが適切
- [ ] ログ出力が適切
- [ ] メソッドが短い（20行以内）

#### 2.2 コントローラー

**確認項目**:
- [ ] Fat Controllerになっていない
- [ ] ビジネスロジックがServiceに委譲されている
- [ ] エラーハンドリングが適切

#### 2.3 モデル

**確認項目**:
- [ ] Fat Modelになっていない
- [ ] バリデーションが適切
- [ ] アソシエーションが適切
- [ ] スコープが適切

---

## 📝 検証レポート作成

検証完了後、以下の形式でレポートを作成してください。

### レポート構成

```markdown
# Phase 7.4: セキュリティ監査自動化 - 検証レポート

## 📋 検証サマリー

- **Phase**: 7.4
- **検証担当**: Codex
- **検証日**: YYYY-MM-DD
- **最終判定**: ✅ 承認 / ⚠️ 条件付き承認 / ❌ 差し戻し

---

## 🔒 セキュリティ検証結果

### 1. 静的解析
- Brakeman: ✅ 警告0件
- bundler-audit: ✅ 脆弱性0件
- RuboCop Security: ✅ 違反0件

### 2. API認証
- [ ] 認証が正しく機能する
- [ ] タイミング攻撃対策済み

### 3. 機密情報の除外
- [ ] スキャン結果から除外済み
- [ ] メール通知に含まれない

### 4. アクセス制御
- [ ] 認証必須
- [ ] 管理者のみアクセス可能

---

## ✅ 機能検証結果

### 1. 静的解析自動化
- [ ] GitHub Actionsワークフロー実装済み
- [ ] スケジュール実行確認済み
- [ ] 通知送信確認済み

### 2. Dependabot設定
- [ ] dependabot.yml実装済み
- [ ] 自動PR作成確認済み

### 3. ログ監視・アラート
- [ ] エラー率監視実装済み
- [ ] トラフィック異常検知実装済み

### 4. セキュリティレポート
- [ ] 週次レポート生成確認済み
- [ ] 管理画面表示確認済み

---

## 🧪 テスト検証結果

- **テスト数**: XX件
- **成功率**: 100%
- **カバレッジ**: XX%

---

## 📊 パフォーマンス検証結果

- **スキャン実行時間**: X分X秒（目標: 10分以内）
- **レポート生成時間**: X分X秒（目標: 3分以内）

---

## 🔍 コード品質検証結果

- **RuboCop**: 違反0件
- **コードレビュー**: 問題なし

---

## ⚠️ 発見された問題

### 問題1: [問題のタイトル]
- **重大度**: High / Medium / Low
- **内容**: [問題の詳細]
- **影響**: [影響範囲]
- **推奨対応**: [対応方法]

---

## ✅ 最終判定

**Phase 7.4は承認します。**

[判定理由]

---

**📝 検証担当**: Codex  
**📅 検証日**: YYYY-MM-DD  
**🎯 Phase**: 7.4  
**✅ 判定**: 承認
```

---

## 🔄 検証完了後の手順

### 1. Kiroへの報告

検証完了後、以下を実施してください：

1. **検証レポート作成**
   - `reports/YYYY-MM-DD/phase-7-4-security-audit-verification-report.md`

2. **Kiroへの通知**
   - 検証完了を報告
   - 検証レポートを共有
   - 受け入れ依頼

### 2. Kiroによる受け入れ

Kiroが以下を実施します：
- 要件との照合
- 設計書との照合
- 受け入れ基準の確認
- 最終承認

---

## 💬 質問・相談

検証中に不明点がある場合は、以下を確認してください：

1. **要件定義書**: `requirements.md`
2. **設計書**: `design.md`
3. **Claude Code実装指示書**: `CLAUDE_CODE_INSTRUCTIONS.md`

それでも不明な場合は、人（ユーザー）に確認してください。

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-02-03  
**🔄 バージョン**: v1.0  
**📋 ステータス**: 検証待ち  
**👨‍💻 実装担当**: Claude Code  
**🔍 検証担当**: Codex  
**✅ 受け入れ担当**: Kiro
