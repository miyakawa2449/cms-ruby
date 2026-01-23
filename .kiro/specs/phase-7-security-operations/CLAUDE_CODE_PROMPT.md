# Claude Code へのプロンプト

以下のプロンプトをClaude Codeに送信してください。

---

# Phase 7: セキュリティ・運用強化 - 実装依頼

こんにちは、Claude Code。Phase 7の実装をお願いします。

## 📋 プロジェクト概要

Railsポートフォリオサイトに、セキュリティと運用機能を追加します。

**主要機能**:
1. 2段階認証（2FA）- Google Authenticator統合
2. 管理画面URL管理 - 動的変更・自動ローテーション
3. 自動バックアップシステム - PostgreSQL、Active Storage、設定ファイル
4. セキュリティ監査自動化 - Brakeman、bundler-audit
5. 監視機能強化 - ヘルスチェック、ダッシュボード
6. 通知機能実装 - メール、Slack
7. 構造化データ拡張 - FAQ、HowTo Schema

## 🤝 作業体制

**あなたの役割**: 実装担当
- 設計書に従って機能を実装
- 基本的なテストを実装
- 正常系の動作確認

**Codexの役割**: 検証担当
- あなたの実装を徹底的に検証
- セキュリティチェック
- エッジケーステスト
- 既存機能への影響確認

**つまり**: あなたは基本的な実装に集中してください。詳細な検証はCodexが担当します。

## 📚 必読ドキュメント

実装前に以下のドキュメントを必ず読んでください：

1. **実装指示書**: `.kiro/specs/phase-7-security-operations/CLAUDE_CODE_INSTRUCTIONS.md`
   - あなた向けの詳細な指示
   - 実装の進め方
   - 注意事項

2. **要件定義書**: `.kiro/specs/phase-7-security-operations/requirements.md`
   - ユーザーストーリー
   - 受け入れ基準
   - 機能要件

3. **設計書**: `.kiro/specs/phase-7-security-operations/design.md`
   - アーキテクチャ設計
   - データベース設計
   - **実装例（これをそのまま使用してください）**

4. **タスクリスト**: `.kiro/specs/phase-7-security-operations/tasks.md`
   - 実装タスクの詳細
   - 実装順序

## 🚀 最初のタスク

**Phase 7.9: 構造化データ拡張**から始めてください。

理由：
- 低リスク（既存機能への影響が少ない）
- 比較的シンプル
- ウォームアップに最適

### タスク内容

1. FAQ Schema実装
2. HowTo Schema実装
3. BreadcrumbList改善
4. Organization Schema実装
5. RSpecテスト実装（5件）
6. Google Rich Results Test検証
7. ドキュメント作成

### 実装方法

設計書（design.md）に実装例があります。**これをそのまま使用してください**。

## ⚠️ 重要な注意事項

### 1. 環境変数を使用

機密情報は環境変数から取得してください：

```ruby
# ✅ 良い例
email = ENV['ADMIN_EMAIL']

# ❌ ダメな例
email = 'user@example.com'
```

### 2. 設計書に従う

設計書の実装例をそのまま使用してください。独自の実装は避けてください。

### 3. 完璧を目指さない

基本的な実装に集中してください。詳細な検証はCodexが担当します。

### 4. 不明点は質問

分からないことがあれば、実装前に質問してください。

## 📝 実装完了時の報告

実装が完了したら、以下の形式で報告してください：

```markdown
## Phase 7.9: 構造化データ拡張 - 実装完了（Codex検証依頼）

### 実装内容
- [x] 9.1 FAQ Schema実装
- [x] 9.2 HowTo Schema実装
- [x] 9.3 BreadcrumbList改善
- [x] 9.4 Organization Schema実装
- [x] 9.5 RSpecテスト実装（5件）
- [x] 9.6 Google Rich Results Test検証
- [x] 9.7 ドキュメント作成

### 実装したファイル
- app/helpers/structured_data_helper.rb
- spec/helpers/structured_data_helper_spec.rb
- docs/seo/structured_data_guide.md

### テスト結果
- RSpecテスト: 5件実装、5件成功
- Rubocop: 問題なし
- 既存テスト: すべて成功

### 自己チェック
- [x] 設計書の実装例に従った
- [x] 基本的なテストを実装した
- [x] すべてのテストが成功した

### Codexへの依頼
以下の検証をお願いします：
- Google Rich Results Testでの検証
- エッジケーステスト
- 既存機能への影響確認

### 懸念事項
なし
```

## 🎯 開始してください

準備ができたら、以下の手順で開始してください：

1. **ドキュメントを読む**
   ```bash
   # 実装指示書を読む
   cat .kiro/specs/phase-7-security-operations/CLAUDE_CODE_INSTRUCTIONS.md
   
   # 設計書を読む（実装例を確認）
   cat .kiro/specs/phase-7-security-operations/design.md
   ```

2. **環境を準備する**
   ```bash
   bundle install
   bundle exec rails db:migrate
   bundle exec rspec  # 既存テストが成功することを確認
   ```

3. **実装を開始する**
   - Phase 7.9から開始
   - 設計書の実装例に従う
   - 基本的なテストを実装
   - テストを実行

4. **Codexに引き継ぐ**
   - 実装完了を報告
   - Codexに検証を依頼

## 💬 質問・相談

不明点や懸念事項があれば、いつでも質問してください。

---

**それでは、Phase 7.9の実装を開始してください。頑張ってください！**
