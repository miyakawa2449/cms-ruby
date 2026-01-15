# タイトル提案機能 デプロイチェックリスト

## Phase 5.2 Week 3 - AI タイトル提案機能追加

### 実装内容

記事編集画面に「タイトル提案」ボタンを追加し、AIが2種類のタイトルを提案する機能を実装しました。

#### 提案されるタイトル
1. **わかりやすいタイトル** - 内容を正確に表現、SEO重視
2. **SNS映えするタイトル** - クリック率重視、感情に訴える

### 変更ファイル一覧

#### 新規作成
- ✅ `app/services/ai/title_suggester.rb` - タイトル生成サービス
- ✅ `spec/services/ai/title_suggester_spec.rb` - サービステスト
- ✅ `spec/requests/admin/ai_controller_spec.rb` - コントローラーテスト
- ✅ `docs/ai_title_suggestion_feature.md` - 詳細仕様書
- ✅ `docs/TITLE_SUGGESTION_QUICKSTART.md` - クイックスタート

#### 変更
- ✅ `app/controllers/admin/ai_controller.rb` - suggest_title アクション追加
- ✅ `app/javascript/controllers/ai_assistant_controller.js` - フロントエンド機能追加
- ✅ `app/views/admin/articles/_form.html.erb` - UI追加
- ✅ `config/routes.rb` - ルーティング追加

### デプロイ前チェックリスト

#### 1. コード品質
- [x] 構文エラーなし（getDiagnostics で確認済み）
- [x] RuboCop 準拠
- [x] JavaScript エラーなし
- [x] テストコード作成済み

#### 2. 機能テスト
- [ ] ローカル環境で動作確認
  - [ ] 記事作成・保存
  - [ ] AI提案ボタンクリック
  - [ ] タイトル候補表示
  - [ ] タイトル選択・適用
- [ ] エラーハンドリング確認
  - [ ] 記事未保存時のエラー
  - [ ] 本文なし時のエラー
  - [ ] API通信エラー時の表示

#### 3. 環境設定
- [ ] AWS Bedrock 認証情報確認
  ```bash
  # .env.production に以下が設定されているか確認
  AWS_BEDROCK_REGION=us-east-1
  AWS_BEDROCK_ACCESS_KEY_ID=xxx
  AWS_BEDROCK_SECRET_ACCESS_KEY=xxx
  ```
- [ ] 本番環境でのAWS接続テスト

#### 4. データベース
- [ ] マイグレーション不要（既存テーブルのみ使用）

#### 5. アセット
- [ ] JavaScript ビルド確認
  ```bash
  npm run build
  # または
  rails assets:precompile
  ```

#### 6. ルーティング
- [ ] ルーティング確認
  ```bash
  rails routes | grep suggest_title
  ```

#### 7. テスト実行
- [ ] RSpec テスト実行
  ```bash
  bundle exec rspec spec/services/ai/title_suggester_spec.rb
  bundle exec rspec spec/requests/admin/ai_controller_spec.rb
  ```

#### 8. セキュリティ
- [x] 管理画面のみアクセス可能（Admin::BaseController 継承）
- [x] CSRF トークン検証
- [x] 認証チェック（before_action）

#### 9. パフォーマンス
- [x] API レスポンスタイムアウト設定
- [x] エラーハンドリング実装
- [x] ローディング表示実装

#### 10. ドキュメント
- [x] 機能仕様書作成
- [x] クイックスタート作成
- [x] デプロイチェックリスト作成

### デプロイ手順

#### 1. コミット
```bash
git add .
git commit -m "feat: AI タイトル提案機能を追加

- わかりやすいタイトル（SEO重視）
- SNS映えするタイトル（クリック率重視）
- 各3個ずつ提案
- 記事編集画面に統合

Phase 5.2 Week 3"
```

#### 2. プッシュ
```bash
git push origin main
```

#### 3. 本番デプロイ（Kamal使用の場合）
```bash
# 環境変数確認
kamal env check

# デプロイ
kamal deploy

# または特定のサービスのみ
kamal app deploy
```

#### 4. デプロイ後確認
```bash
# アプリケーションログ確認
kamal app logs

# コンテナ状態確認
kamal app details
```

#### 5. 動作確認
- [ ] 本番環境にアクセス
- [ ] 管理画面ログイン
- [ ] 記事編集画面で「AI提案」ボタン確認
- [ ] タイトル提案機能の動作確認
- [ ] エラーログ確認

### ロールバック手順

問題が発生した場合：

```bash
# 前のバージョンにロールバック
kamal app rollback

# または Git で戻す
git revert HEAD
git push origin main
kamal deploy
```

### 監視項目

デプロイ後、以下を監視：

1. **エラーログ**
   ```bash
   kamal app logs --tail 100
   ```

2. **AWS Bedrock API 使用状況**
   - API コール数
   - エラー率
   - レスポンスタイム

3. **ユーザーフィードバック**
   - 機能の使用頻度
   - エラー報告

### トラブルシューティング

#### JavaScript が動作しない
```bash
# アセット再ビルド
rails assets:precompile RAILS_ENV=production
kamal app deploy
```

#### AWS 接続エラー
```bash
# 環境変数確認
kamal env check

# 環境変数更新
kamal env push
kamal app restart
```

### 完了確認

- [ ] 本番環境で正常動作
- [ ] エラーログなし
- [ ] ユーザーテスト完了
- [ ] ドキュメント更新完了

### 次のステップ

- [ ] ユーザーフィードバック収集
- [ ] 使用状況分析
- [ ] 改善点の洗い出し
- [ ] 次の機能開発計画

---

**実装者**: Kiro AI Assistant  
**実装日**: 2026-01-15  
**Phase**: 5.2 Week 3  
**Status**: ✅ 実装完了 → デプロイ待ち
