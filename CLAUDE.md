# Portfolio Site Project - Claude Memory

## 🚀 セッション開始時の必須チェック項目

**新しいセッション開始時は、必ず以下を実行してください：**

### 1. プロジェクト状況確認（必須）
```
/docs/specifications/spec.md の「改訂履歴」セクションをチェック
→ 最新の仕様変更・完成状況を把握
```

### 2. 今日のタスク確認（必須）  
```
TOMORROW_TASKS.md をチェック
→ 当日実施すべきタスクを把握・優先順位確認
```

### 3. プロジェクト完成度確認（推奨）
```
README.md の「プロジェクト完了度」セクションをチェック
→ 現在のPhase進捗・次のマイルストーンを確認
```

### ⚡️ クイック開始コマンド例
ユーザーが「session-start」と入力した場合：
1. spec.md の改訂履歴を読み取り、最新状況を要約
2. TOMORROW_TASKS.md のタスクリストを確認・整理
3. 今日の作業方針を提案

---

## プロジェクト概要
シニアエンジニアの技術発信・ポートフォリオサイト
- Ruby on Rails 8.1.1 + Tailwind CSS（最新版対応）
- PostgreSQL + Sidekiq 8.0.10 + OpenAI API（依存関係最適化済み）
- JWT 3.1.2（セキュリティ強化）・ruby-openai 8.3.0（AI機能改善）
- AWS Lightsail（本番環境）

## 現在の状況
- **フェーズ**: Phase 2C-R完全完了 → Phase 2C認証・CMS基盤実装
- **技術基盤**: Rails 8.1.1再構築・セキュリティ問題全解決・最新gem環境完備
- **仕様書**: `/docs/specifications/spec.md`（Rails 8.1.1対応）・Phase計画書完備
- **開発方針**: アジャイル開発（2週間スプリント・11スプリント構成）
- **完成状況**: 17画面プロトタイプ・18+2テーブルDB完全構築・Rails 8.1.1環境構築完了

## 主要機能
1. **ポートフォリオCMS**: 8セクション構成の縦スクロール型
2. **技術ブログ**: Markdown + カテゴリ階層 + 検索
3. **メディアライブラリ**: 画像管理・最適化
4. **SEO/AEO**: 自動最適化 + AI連携
5. **管理画面**: セキュリティ強化（パス変更可能）

## 技術的な決定事項
- **管理画面パス**: デフォルト `/admin` だが変更可能
- **AI機能**: GPT APIで記事要約・キーワード抽出
- **画像処理**: WebP自動変換 + 遅延読み込み
- **検索**: PostgreSQL全文検索
- **SNS埋め込み**: oEmbed対応

## 次のタスク
- [x] 画面モック作成（17画面完成済み）
- [x] DB schema設計（18+2テーブル完全構築済み）
- [x] Railsマイグレーション完了（全20マイグレーション実行済み）
- [x] API設計完了（公開API + 内部API）
- [x] Phase 1: 仕様策定完全完了
- [x] **Phase 2A完了**: Rails環境構築・設定ファイル作成完了
- [x] **Phase 2B完了**: Phase 1再設計・全マイグレーション・フロントエンド統合完了
- [x] **Phase 2C-R完了**: Rails 8.1.1再構築・セキュリティアップデート・依存関係解決
- [ ] **Phase 2C開始**: 認証・CMS基盤実装（Rails 8.1.1対応）
  - [ ] Devise設定・管理画面ログイン機能（Rails 8.1.1対応）
  - [ ] ポートフォリオCMS基本機能（Section/SectionContent）
  - [ ] ブログCMS基本機能（Article/Category）
  - [ ] Rails 8.1.1サーバー起動・動作確認・新gem動作テスト

## 開発ルール
- テスト駆動開発（TDD）
- 各Sprint後に本番デプロイ
- コードレビュー必須

## 重要な決定
- Rails 8.1.1採用による長期サポート・最新機能活用
- 全Dependabotセキュリティ問題解決（JWT 3.1.2、ruby-openai 8.3.0等）
- Sidekiq 8.0.10 + sidekiq-cron 2.3.1互換性確認済み
- カテゴリは2階層まで・AI機能は非同期処理・管理画面セキュリティ重視

## 参考資料
### 主要仕様書
- **総合仕様書**: `/docs/specifications/spec.md`（Rails 8.1.1対応済み）
- **Phase計画書**: `/docs/development/phase_plan_rails_8_1.md`（Rails 8.1.1版・最新）
- **データベース設計v2**: `/docs/database/schema_design_v2.md`（Rails 8.0→8.1対応）
- **ER図v2**: `/docs/database/er_diagram_v2.mermaid`（最新関係図）
- **マイグレーション計画v2**: `/docs/database/migrations_plan_v2.md`（実行済み）
- **API設計**: `/docs/api/api_design.md`
- **実装計画**: `/docs/development/api_implementation_plan.md`

### プロトタイプ（17画面完成）
- **フロントエンド**: `/docs/wireframes/app/views/portfolio/`・`/blog/`
- **管理画面**: `/docs/wireframes/app/views/admin/`

### その他
- My Story画像: `/Users/tsuyoshi/Downloads/My-Story-なぜ要件定義から実装まで一人でできるのか-宮川-剛-11-26-2025_01_11_PM.png`

---

## 💡 使用方法

### セッション開始時
ユーザーが「**session-start**」と入力すると：
1. 最新の仕様変更・プロジェクト状況を自動チェック
2. 直近3日分のレポートを確認
3. 今日のタスクリストを確認・整理
4. 作業開始の提案を実施

### 重要なコマンド
- `session-start` - セッション開始時の状況確認
- `spec.md` の改訂履歴確認 - 最新仕様把握
-　`reports` フォルダのレポート確認 - 最新3日分の把握
- `TOMORROW_TASKS.md` 確認 - 当日タスク把握