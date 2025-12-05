# Portfolio Site Project - Claude Memory

## 🚀 セッション開始時の必須チェック項目

**新しいセッション開始時は、必ず以下を実行してください：**

### 1. プロジェクト現況把握（必須）
```
/docs/specifications/spec.md の「改訂履歴」セクション
→ Phase 2C完了・Phase 3開始準備状況・My Story仕様確認

TOMORROW_TASKS.md のPhase 3優先タスク
→ セクション管理・公開API実装・フロントエンド統合

最新レポート（/reports/2025-12-05/）
→ 直近実装内容・解決済み課題・技術判断履歴
```

### 2. 技術環境確認（推奨）
```
Docker環境動作確認: docker-compose up
管理画面動作確認: http://localhost:3000/admin
データベース状況: rails console → AdminUser.count, Section.count
```

### 3. 実装状況確認（必要時）
```
git status → 未コミット変更確認
git log --oneline -n 5 → 最新コミット履歴
プロジェクト完成度: README.md（約55%完了）
```

### ⚡️ クイック開始コマンド例
ユーザーが「session-start」と入力した場合：
1. spec.md の改訂履歴を読み取り、Phase 2C完了・Phase 3準備状況を要約
2. TOMORROW_TASKS.md のPhase 3タスクリスト確認・優先順位整理
3. 最新レポート確認で直近実装内容・課題解決状況把握
4. 今日の作業方針（セクション管理・公開API）を提案

---

## プロジェクト概要
シニアエンジニアの技術発信・ポートフォリオサイト
- Ruby on Rails 8.1.1 + Tailwind CSS（最新版対応）
- PostgreSQL 17-alpine + Sidekiq 8.0.10 + OpenAI API（ICUロケール・依存関係最適化済み）
- JWT 3.1.2（セキュリティ強化）・ruby-openai 8.3.0（AI機能改善）
- AWS Lightsail（本番環境）

## 🎯 実装優先度（Phase 3完了基準）
1. **My Story独立ページ実装**（最重要・仕様書準拠）
2. **コンタクトフォーム機能実装**（フォーム送信・Slack通知）
3. **公開API実装**（記事・カテゴリ・タグ・セクション）
4. **フロントエンド統合完成**（レスポンシブ・検索・ナビゲーション）

## 🎯 現在の状況（2025-12-05更新）

### 完成済み基盤（Phase 2C完了）
- **フェーズ**: Phase 2C完全完了 → Phase 3セクション管理実装完了
- **技術基盤**: Rails 8.1.1・PostgreSQL 17・Tailwind CSS 3.x完全統合
- **認証・CMS**: AdminUser・記事/カテゴリ/タグ・セクション管理動作確認済み
- **実装規模**: 91ファイル変更・3,515行追加・8セクション対応

### Phase 3実装完了機能
- ✅ **セクション管理**: JSONBコンテンツ・8セクションCRUD・カスタムフォーム
- ✅ **My Story基盤**: HTMLプロトタイプ467行・スクロールアニメーション
- 🚀 **次期実装**: 公開API・フロントエンド統合・ポートフォリオ表示完成

## 📖 My Story実装仕様（重要度: 高）

### 独立ページ設計
- **URL構成**: `/my-story`（独立ページ・ポートフォリオからリンク）
- **ストーリー構成**: 3段階キャリアタイムライン（1994-2005講師 → 2005-2021 SE/PM → 2022-現在AIエンジニア）
- **UI要素**: スクロールアニメーション・2カラムレイアウト・実績事例・CTA誘導

### 技術実装詳細
- **プロトタイプ完成**: `/docs/wireframes/app/views/portfolio/my_story_prototype.html`（467行・レスポンシブ対応）
- **SEO対応**: 構造化データ（Person/Article）・適切見出し構造・メタディスクリプション
- **アニメーション**: タイムライン段階的表示・章ごとフェードイン・プログレスバー

### CMS管理要件
- **コンテンツ管理**: 各章テキスト・画像・タイムライン情報・引用文編集
- **実績管理**: プロジェクト事例3件（タイトル・説明・技術スタック・期間・規模）
- **CTA設定**: お問い合わせボタン・実績詳細リンク・テキスト自由編集

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
- **検索**: PostgreSQL 17全文検索（ICUロケール対応）
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
- [x] **Phase 2C完了**: 認証・CMS基盤実装完全完了
  - [x] Devise設定・AdminUser認証・ログイン画面（レスポンシブデザイン適用済み）
  - [x] 記事管理（Article）: 作成・編集・削除・公開・下書き・タグ/カテゴリ連携
  - [x] カテゴリ管理（Category）: 階層構造・CRUD・記事数カウント・デザイン設定
  - [x] タグ管理（Tag）: CRUD・検索・記事数カウント・関連記事表示
  - [x] 管理画面基盤: ナビゲーション・Tailwind CSS・レスポンシブ対応
  - [x] モデル改善: slug重複解決・リアルタイム記事数更新・安全削除機能
- [ ] **Phase 3開始**: セクション管理・公開API実装
  - [ ] セクション管理（Section/SectionContent）実装・ポートフォリオ機能完成
  - [ ] 公開API実装（articles, categories, tags, sections）
  - [ ] フロントエンド統合・ポートフォリオ表示機能

## 開発ルール
- テスト駆動開発（TDD）
- 各Sprint後に本番デプロイ
- コードレビュー必須

## 重要な決定
- Rails 8.1.1採用による長期サポート・最新機能活用
- 全Dependabotセキュリティ問題解決（JWT 3.1.2、ruby-openai 8.3.0等）
- Sidekiq 8.0.10 + sidekiq-cron 2.3.1互換性確認済み
- カテゴリは2階層まで・AI機能は非同期処理・管理画面セキュリティ重視

## 📚 参考資料（優先度順・用途別整理）

### Phase 3実装用（最優先）
- **TOMORROW_TASKS.md**: セクション管理・公開API・フロントエンド統合タスク
- **My Story仕様**: `/docs/specifications/spec.md`（行166-171・要件明確化済み）
- **My Storyプロトタイプ**: `/docs/wireframes/app/views/portfolio/my_story_prototype.html`（467行完成）
- **My Storyワイヤーフレーム**: `/docs/wireframes/02_my_story.md`（設計詳細）

### 技術仕様（実装時参照）
- **総合仕様書**: `/docs/specifications/spec.md`（Phase 2C完了反映・Rails 8.1.1対応）
- **データベース設計v2**: `/docs/database/schema_design_v2.md`（JSONBマイグレーション対応）
- **API設計**: `/docs/api/api_design.md`（公開API・内部API設計）
- **Phase計画書**: `/docs/development/phase_plan_rails_8_1.md`（Phase進捗・マイルストーン）

### プロトタイプ（17画面完成）
- **ポートフォリオ**: `/docs/wireframes/app/views/portfolio/portfolio_prototype.html`
- **管理画面**: `/docs/wireframes/app/views/admin/`（12画面・レスポンシブ対応）
- **ブログ**: `/docs/wireframes/app/views/blog/`（3画面・検索機能付き）

### 実装履歴・課題解決（問題発生時参照）
- **最新実装**: `/reports/2025-12-05/1st.md`（Phase 3セクション管理完了）
- **CSS問題解決**: `/reports/2025-12-04/3rd.md`（Tailwind CSS統合）
- **Phase 2C完了**: `/reports/2025-12-03/3rd.md`（CMS基盤実装）
- **技術決定履歴**: `/reports/2025-12-02/`（データベース・フロントエンド統合）

---

## 💡 使用方法

### セッション開始時
ユーザーが「**session-start**」と入力した場合：
1. Phase 2C完了・Phase 3進捗状況を自動チェック
2. TOMORROW_TASKS.md で優先タスク（公開API・フロントエンド統合）確認
3. 最新レポート（/reports/2025-12-05/）で直近実装・技術判断確認
4. My Story・セクション管理の次期作業提案

### 重要なコマンド
- `session-start` - Phase 3進捗・技術状況総合確認
- `add-report [タイトル]` - 日次作業報告書の自動生成
- `spec.md` 改訂履歴 - Phase 2C完了・Phase 3仕様確認
- `最新レポート確認` - 実装判断・課題解決履歴把握
- `TOMORROW_TASKS.md` - 公開API・フロントエンド統合タスク

## 🛠 実装品質ガイドライン

### Rails 8.1.1準拠開発
- **Strong Parameters**: 明示的フィールド許可・`to_unsafe_h`禁止
- **JSONB活用**: PostgreSQL GINインデックス対応・柔軟データ構造
- **セキュリティ**: JWT 3.1.2・Devise最新版・入力検証徹底

### 問題解決アプローチ
1. **症状特定**: エラーメッセージ・ブラウザ動作・ログ確認
2. **過去事例活用**: reports/ ディレクトリの類似問題解決法参照
3. **段階的修正**: 最小変更・動作確認・リグレッション防止
4. **ドキュメント更新**: 技術判断・解決策のレポート記録

### add-report コマンド
ユーザーが「**add-report**」または「**add-report タイトル**」と入力すると：
1. 現在の日付でreportsフォルダ内にディレクトリを作成
2. 連番ファイル名（1st.md, 2nd.md, etc.）を自動生成
3. Git情報（最新コミット、ブランチ、変更ファイル）を自動取得
4. 作業報告書テンプレートを自動生成
5. 完了タスク・実装内容・課題・次回申し送りなどの構造化されたフォーマット
6. 編集可能な状態で作成完了を報告

**使用例**:
- `add-report` → 「作業報告 1st」などのデフォルトタイトル
- `add-report "Phase 3完了報告"` → 指定されたタイトルで作成