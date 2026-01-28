# Claude Code へのプロンプト - Phase 7.2

## 📋 依頼内容

Phase 7.2（管理画面URL管理）の実装をお願いします。

## 🎯 実装目標

管理画面のURLを動的に変更できる機能を実装してください。自動ローテーション機能により、定期的にURLを変更してセキュリティを強化します。

## 📚 実装指示書

詳細な実装手順は以下のファイルに記載されています：

```
.kiro/specs/phase-7.2-admin-url-management/CLAUDE_CODE_PHASE_7_2_INSTRUCTIONS.md
```

このファイルを必ず読んでから実装を開始してください。

## 🔑 重要なポイント

### 1. Phase 7.8の通知機能を使用
- `AdminPathMailer#path_changed` - URL変更通知
- `AdminPathMailer#rotation_notification` - 自動ローテーション通知
- `SlackNotifier#notify_admin_path_changed` - Slack通知

**これらは既に実装済みなので、呼び出すだけでOKです。**

### 2. Phase 7.1の経験を活かす
- Turbo対応（`data: { turbo: false }`）
- CSP対応（インラインJS排除）
- 確認ダイアログ（`data: { confirm: '...' }`）

### 3. 基本実装に集中
- 設計書の実装例をそのまま使用してください
- 過剰な機能追加は避けてください
- シンプルで確実な実装を心がけてください

### 4. テストは最小限
- 目標15件のテストを実装してください
- エッジケースは後でCodexが追加します
- 基本的な動作確認に集中してください

## 📦 実装範囲（11タスク）

### URL変更機能（Day 1-2）
- ✅ 2.1 AdminPathHistoryモデル作成
- ✅ 2.2 AdminPath::Updaterサービス実装
- ✅ 2.3 URL変更画面UI実装
- ✅ 2.4 環境変数更新機能実装

### 自動ローテーション（Day 3-4）
- ✅ 2.5 AdminPath::RotationJob実装
- ✅ 2.6 Sidekiq-cronスケジュール設定
- ✅ 2.7 ローテーション設定画面UI実装
- ✅ 2.8 緊急ローテーション機能実装

### テスト・ドキュメント（Day 5）
- ✅ 2.9 RSpecテスト実装（15件）
- ⚠️ 2.10 E2Eテスト実装（2件）※オプション
- ⚠️ 2.11 ドキュメント作成 ※オプション

## ⚠️ 重要な注意事項

### 1. 環境変数の扱い
- `.env.production` ファイルを直接編集します
- 本番環境では慎重に扱ってください
- バックアップを取ってから変更してください

### 2. セキュリティ
- 予約語チェックを必ず実装してください
- URL形式のバリデーションを厳格に行ってください
- 変更履歴を必ず記録してください

### 3. 通知
- URL変更時は必ず通知を送信してください
- 緊急ローテーション時は即座に通知してください

## 🤝 Codexとの協働

### 実装完了後
1. 全テストを実行してください
2. 開発環境で動作確認してください
3. Codexに検証を依頼してください

### Codexへの依頼内容
- セキュリティチェック（予約語、バリデーション）
- エッジケーステスト追加
- 本番環境での動作確認
- 既存機能への影響確認

## 📚 参考資料

### 必読
- `.kiro/specs/phase-7.2-admin-url-management/CLAUDE_CODE_PHASE_7_2_INSTRUCTIONS.md` - 実装指示書
- `.kiro/specs/phase-7.2-admin-url-management/design.md` - 設計書
- `.kiro/specs/phase-7.2-admin-url-management/tasks.md` - タスクリスト
- `.kiro/specs/phase-7.2-admin-url-management/requirements.md` - 要件定義書

### 参考実装
- `app/mailers/admin_path_mailer.rb` - Phase 7.8で実装済み
- `app/services/slack_notifier.rb` - Phase 7.8で実装済み
- `app/controllers/admin/two_factor_auth_controller.rb` - Phase 7.1の実装例

## 🚀 開始方法

### 1. 実装指示書を読む
```bash
cat .kiro/specs/phase-7.2-admin-url-management/CLAUDE_CODE_PHASE_7_2_INSTRUCTIONS.md
```

### 2. 設計書を確認
```bash
cat .kiro/specs/phase-7.2-admin-url-management/design.md
```

### 3. 実装開始
```bash
# Step 1から順番に実装してください
docker compose exec web bin/rails generate model AdminPathHistory ...
```

## ✅ 完了条件

### 必須
- [ ] 全11タスク完了
- [ ] 全テスト成功（15件以上）
- [ ] 開発環境での動作確認完了

### オプション
- [ ] E2Eテスト実装（2件）
- [ ] ドキュメント作成

---

**Phase 7.1の経験を活かして、高品質な実装を期待しています！**

**実装完了後は、Codexに検証を依頼してください。**

---

**📝 作成者**: Kiro（仕様管理担当）  
**📅 作成日**: 2026-01-23  
**🎯 Phase**: 7.2 管理画面URL管理  
**👨‍💻 実装担当**: Claude Code  
**🔍 検証担当**: Codex
