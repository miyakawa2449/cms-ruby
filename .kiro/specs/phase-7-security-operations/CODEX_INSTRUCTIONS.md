# Phase 7: セキュリティ・運用強化 - Codexデバッグ指示書

## 📋 概要

Phase 7では、2段階認証、管理画面URL管理、自動バックアップシステム、セキュリティ監査自動化、監視機能強化を実装します。

**重要**: このフェーズはセキュリティに関わるデリケートな作業です。慎重に進めてください。

---

## 🎯 Codexの役割

あなた（Codex）は**デバッグ担当**として、以下の責任を持ちます：

1. **テスト失敗時の原因切り分け**: Claude Codeが実装した機能のテストが失敗した場合、原因を特定する
2. **安全な削除・変更の判断**: 不要なコードや危険なコードを安全に削除・変更できるか判断する
3. **検証ログの記録**: デバッグ過程と結果を詳細に記録する
4. **再現手順の文書化**: 問題の再現手順を明確に文書化する

**重要な原則**:
- 実装はClaude Codeが担当する（Codexは実装しない）
- テストの失敗原因を特定し、Claude Codeに修正を依頼する
- 安全性の判断が困難な場合は、必ず人に確認する
- デバッグ過程を詳細に記録し、再発防止に役立てる

---

## 📚 必読ドキュメント

実装前に以下のドキュメントを必ず読んでください：

1. **要件定義書**: `.kiro/specs/phase-7-security-operations/requirements.md`
   - ユーザーストーリー
   - 受け入れ基準
   - 機能要件
   - 非機能要件

2. **設計書**: `.kiro/specs/phase-7-security-operations/design.md`
   - アーキテクチャ設計
   - データベース設計
   - API設計
   - セキュリティ設計
   - 実装例

3. **タスクリスト**: `.kiro/specs/phase-7-security-operations/tasks.md`
   - 実装タスクの詳細
   - 実装順序
   - 依存関係

4. **AWS S3バックアップガイド**: `docs/infrastructure/aws_s3_backup_guide.md`
   - AWS S3の設定方法
   - バックアップの仕組み
   - コスト試算

---

## 🔧 デバッグの進め方

### ステップ1: テスト失敗の検知

Claude Codeが実装した機能のテストが失敗した場合、デバッグを開始します。

**テスト実行コマンド**:

```bash
# 特定のテストファイルを実行
bundle exec rspec spec/models/admin_user_spec.rb

# 特定のテストを実行
bundle exec rspec spec/models/admin_user_spec.rb:10

# すべてのテストを実行
bundle exec rspec

# Rubocopチェック
bundle exec rubocop

# Brakemanセキュリティチェック
bundle exec brakeman
```

**すべてのテストが成功することを確認してください。**

### ステップ5: 動作確認

テストが成功したら、実際に動作確認を行ってください：

1. **開発サーバー起動**: `bin/dev`
2. **ブラウザでアクセス**: `http://localhost:3000`
3. **機能を実際に使ってみる**
4. **エラーログを確認**: `log/development.log`

### ステップ6: 報告

実装が完了したら、以下の形式で報告してください：

```markdown
## Phase 7.X: [機能名] - 実装完了報告

### 実装内容
- [x] タスク1: [タスク名]
- [x] タスク2: [タスク名]
- [x] タスク3: [タスク名]

### テスト結果
- RSpecテスト: XX件実装、XX件成功
- Rubocop: 問題なし
- Brakeman: 問題なし

### 動作確認
- [x] 機能A: 正常動作確認
- [x] 機能B: 正常動作確認

### 問題点・懸念事項
- なし

または

- 問題1: [詳細]
- 問題2: [詳細]

### 次のステップ
Phase 7.X+1に進みます。
```

---

## ⚠️ 重要な注意事項

### 1. 環境変数の取り扱い

**絶対にやってはいけないこと**:
- ❌ 実際のメールアドレスをコードに直接書く
- ❌ Slack Webhook URLをコードに直接書く
- ❌ AWS認証情報をコードに直接書く
- ❌ 秘密鍵をコードに直接書く

**正しい方法**:
- ✅ 環境変数から取得する: `ENV['ADMIN_EMAIL']`
- ✅ `.env`ファイルに設定する（Gitにコミットしない）
- ✅ `.env.example`にプレースホルダーを記載する

### 2. データベースマイグレーション

**マイグレーション実行前の確認**:
- [ ] マイグレーションファイルをレビューした
- [ ] ロールバック方法を確認した
- [ ] 本番環境への影響を考慮した

**マイグレーション実行**:
```bash
# 開発環境
bundle exec rails db:migrate

# ロールバック（問題があった場合）
bundle exec rails db:rollback

# マイグレーションステータス確認
bundle exec rails db:migrate:status
```

### 3. 既存機能への影響

Phase 7の実装が既存機能に影響を与えないか確認してください：

**確認項目**:
- [ ] 既存のテストがすべて成功する
- [ ] 既存の管理画面が正常に動作する
- [ ] 既存のログイン機能が正常に動作する
- [ ] 既存のメール送信機能が正常に動作する

**既存テスト実行**:
```bash
# すべてのテストを実行
bundle exec rspec

# 特定のディレクトリのテストを実行
bundle exec rspec spec/models
bundle exec rspec spec/controllers
bundle exec rspec spec/services
```

### 4. セキュリティチェック

実装後、必ずセキュリティチェックを行ってください：

```bash
# Brakemanセキュリティスキャン
bundle exec brakeman

# bundler-audit（依存関係の脆弱性チェック）
bundle exec bundle audit check

# Rubocopセキュリティチェック
bundle exec rubocop --only Security
```

**脆弱性が見つかった場合は、必ず修正してください。**

---

## 🐛 トラブルシューティング

### よくある問題と解決方法

#### 問題1: gem依存関係のエラー

```bash
# Gemfileを更新した後
bundle install

# 依存関係の問題がある場合
bundle update [gem名]
```

#### 問題2: データベース接続エラー

```bash
# データベースの状態確認
bundle exec rails db:migrate:status

# データベースのリセット（開発環境のみ）
bundle exec rails db:reset

# データベースの再作成
bundle exec rails db:drop db:create db:migrate db:seed
```

#### 問題3: テスト失敗

```bash
# テストデータベースのリセット
RAILS_ENV=test bundle exec rails db:reset

# 特定のテストを詳細モードで実行
bundle exec rspec spec/models/admin_user_spec.rb --format documentation

# テストのデバッグ
# テストファイルに binding.pry を追加して実行
```

#### 問題4: Sidekiqジョブが実行されない

```bash
# Sidekiqの起動確認
ps aux | grep sidekiq

# Sidekiqの再起動
# Ctrl+C で停止後
bundle exec sidekiq

# Sidekiq-cronのスケジュール確認
bundle exec rails console
> Sidekiq::Cron::Job.all
```

---

## 📝 実装チェックリスト

各タスク実装時に、以下のチェックリストを使用してください：

### 実装前
- [ ] 要件定義書を読んだ
- [ ] 設計書を読んだ
- [ ] 実装例を理解した
- [ ] 依存関係を確認した
- [ ] 環境変数を確認した

### 実装中
- [ ] 設計書の実装例に従っている
- [ ] セキュリティ対策を実装している
- [ ] エラーハンドリングを実装している
- [ ] ログを適切に記録している
- [ ] コメントを適切に記述している

### 実装後
- [ ] RSpecテストを実装した
- [ ] すべてのテストが成功した
- [ ] Rubocopチェックが成功した
- [ ] Brakemanチェックが成功した
- [ ] 動作確認を行った
- [ ] 既存機能への影響を確認した
- [ ] ドキュメントを更新した（必要に応じて）

---

## 🤝 コミュニケーション

### 質問するタイミング

以下の場合は、実装前に必ず質問してください：

1. **要件が不明確**: ユーザーストーリーや受け入れ基準が理解できない
2. **設計に矛盾**: 設計書に矛盾や不整合がある
3. **実装方法が不明**: 実装例がなく、どう実装すべきか分からない
4. **セキュリティ懸念**: セキュリティ上の懸念がある
5. **既存機能への影響**: 既存機能に影響を与える可能性がある

### 質問の形式

質問する際は、以下の形式で質問してください：

```markdown
## 質問: [タスク名]

### 状況
[現在の状況を説明]

### 問題
[何が問題なのかを説明]

### 確認したこと
- [確認したドキュメント]
- [試したこと]

### 質問
[具体的な質問]

### 提案（あれば）
[解決策の提案]
```

---

## 📊 進捗報告

### 日次報告

毎日の作業終了時に、以下の形式で進捗を報告してください：

```markdown
## Phase 7 進捗報告 - YYYY-MM-DD

### 本日の作業
- [x] タスク1: [タスク名] - 完了
- [ ] タスク2: [タスク名] - 進行中（XX%）

### 完了したタスク数
- 本日: X件
- 累計: XX/76件（XX%）

### テスト結果
- RSpecテスト: XX件実装、XX件成功
- Rubocop: 問題なし
- Brakeman: 問題なし

### 問題・ブロッカー
- なし

または

- 問題1: [詳細と対応方針]

### 明日の予定
- タスクX: [タスク名]
- タスクY: [タスク名]
```

---

## 🎯 成功基準

Phase 7の実装が成功したと判断する基準：

### 機能要件
- [ ] すべての受け入れ基準を満たしている
- [ ] 90件以上のRSpecテストが実装されている
- [ ] すべてのテストが成功している
- [ ] テストカバレッジが85%以上

### 非機能要件
- [ ] バックアップ実行時間が15分以内
- [ ] 復元時間が30分以内
- [ ] ヘルスチェックレスポンスタイムが100ms以内
- [ ] バックアップ成功率が99.9%以上

### セキュリティ
- [ ] Brakemanで脆弱性が検出されない
- [ ] bundler-auditで脆弱性が検出されない
- [ ] 2FAが正常に動作する
- [ ] バックアップが暗号化されている

### コード品質
- [ ] Rubocopで警告が出ない
- [ ] コードレビューで指摘事項がない
- [ ] ドキュメントが更新されている

---

## 📚 参考資料

### 技術ドキュメント
- [devise-two-factor](https://github.com/tinfoil/devise-two-factor)
- [AWS SDK for Ruby - S3](https://docs.aws.amazon.com/sdk-for-ruby/v3/api/Aws/S3.html)
- [Brakeman](https://brakemanscanner.org/)
- [bundler-audit](https://github.com/rubysec/bundler-audit)
- [Sidekiq-cron](https://github.com/sidekiq-cron/sidekiq-cron)
- [RSpec](https://rspec.info/)

### プロジェクト内ドキュメント
- Phase 6最終レビューレポート: `reports/2026-01-22/kiro-phase6-final-review.md`
- Phase計画書: `docs/development/phase_plan_rails_8_1_1.md`
- セキュリティ実装ガイド: `docs/security/`

---

## 🚀 開始方法

Phase 7の実装を開始する準備ができたら、以下の手順で開始してください：

### 1. ドキュメントの確認
```bash
# 要件定義書を読む
cat .kiro/specs/phase-7-security-operations/requirements.md

# 設計書を読む
cat .kiro/specs/phase-7-security-operations/design.md

# タスクリストを読む
cat .kiro/specs/phase-7-security-operations/tasks.md
```

### 2. 環境の準備
```bash
# 依存関係のインストール
bundle install

# データベースのマイグレーション
bundle exec rails db:migrate

# テストの実行（既存テストが成功することを確認）
bundle exec rspec
```

### 3. 最初のタスクの選択

タスクリストから最初のタスクを選択してください。

**推奨**: Phase 7.1（2段階認証）から開始

### 4. 実装開始の宣言

実装を開始する前に、以下の形式で宣言してください：

```markdown
## Phase 7.1: 2段階認証（2FA）実装 - 開始

### 実装予定タスク
- [ ] 1.1 devise-two-factor, rqrcode gem追加
- [ ] 1.2 AdminUserモデル拡張（マイグレーション）
- [ ] 1.3 2FA設定画面UI実装
- [ ] 1.4 QRコード生成機能実装
...

### 実装期間
開始: YYYY-MM-DD
完了予定: YYYY-MM-DD（5日間）

### 確認事項
- [x] 要件定義書を読んだ
- [x] 設計書を読んだ
- [x] 実装例を理解した
- [x] 環境変数を確認した

実装を開始します。
```

---

**頑張ってください！何か質問があれば、いつでも聞いてください。**

**作成者**: Kiro（仕様管理担当）  
**作成日**: 2026-01-22  
**対象**: Codex（実装担当）
