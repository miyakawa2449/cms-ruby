# AWS Bedrock セットアップガイド

## 📋 目次
1. [前提条件](#前提条件)
2. [AWS アカウント設定](#aws-アカウント設定)
3. [Bedrock モデルアクセス申請](#bedrock-モデルアクセス申請)
4. [IAM ユーザー作成](#iam-ユーザー作成)
5. [アクセスキー作成](#アクセスキー作成)
6. [ローカル環境設定](#ローカル環境設定)
7. [動作確認](#動作確認)
8. [本番環境設定](#本番環境設定)
9. [トラブルシューティング](#トラブルシューティング)

---

## 前提条件

- ✅ AWSアカウントを持っている
- ✅ クレジットカードが登録されている（従量課金）
- ✅ 管理者権限でAWSコンソールにアクセスできる

---

## AWS アカウント設定

### 1. AWSコンソールにログイン
https://console.aws.amazon.com/

### 2. リージョンを選択
**重要**: Bedrockが利用可能なリージョンを選択してください。

推奨リージョン:
- 🇺🇸 **us-east-1** (バージニア北部) - 最も多くのモデルが利用可能
- 🇺🇸 us-west-2 (オレゴン)
- 🇪🇺 eu-central-1 (フランクフルト)
- 🇯🇵 ap-northeast-1 (東京) - 一部モデルのみ

**このガイドでは us-east-1 を使用します。**

画面右上のリージョン選択で「米国東部（バージニア北部）us-east-1」を選択してください。

---

## Bedrock モデルアクセス申請

### 1. Bedrockコンソールを開く

1. AWSコンソールの検索バーに「Bedrock」と入力
2. 「Amazon Bedrock」を選択
3. 左メニューから「Model access」（モデルアクセス）を選択

### 2. モデルアクセスをリクエスト

1. 「Manage model access」（モデルアクセスを管理）ボタンをクリック
2. 以下のモデルにチェックを入れる:
   - ✅ **Anthropic - Claude Sonnet 4.5** ⭐ 推奨（最新・最高性能）
   - ✅ **Anthropic - Claude Haiku 4.5** ⭐ 推奨（高速・高品質）
   - ⚪ Anthropic - Claude 3.5 Sonnet（旧世代・オプション）
   - ⚪ Anthropic - Claude 3 Haiku（旧世代・オプション）
3. 「Request model access」（モデルアクセスをリクエスト）ボタンをクリック

**推奨**: Claude 4.5シリーズを使用してください。性能が大幅に向上しています。

### 3. アクセス承認を待つ

- 通常は**即座に承認**されます（数秒〜数分）
- ステータスが「Access granted」（アクセス許可済み）になるまで待つ
- リフレッシュボタンで状態を確認

**確認方法**:
```
Model access ページで以下が表示されればOK:
✅ Claude Sonnet 4.5 - Access granted
✅ Claude Haiku 4.5 - Access granted
```

---

## IAM ユーザー作成

開発用のIAMユーザーを作成します。

### 1. IAMコンソールを開く

1. AWSコンソールの検索バーに「IAM」と入力
2. 「IAM」を選択
3. 左メニューから「Users」（ユーザー）を選択

### 2. ユーザーを作成

1. 「Create user」（ユーザーを作成）ボタンをクリック
2. ユーザー名を入力: `bedrock-dev-user`
3. 「Next」をクリック

### 3. 権限を設定

**オプション1: 既存ポリシーを直接アタッチ（簡単）**

1. 「Attach policies directly」を選択
2. 検索バーに「Bedrock」と入力
3. 以下のポリシーにチェック:
   - ✅ `AmazonBedrockFullAccess`
4. 「Next」→「Create user」をクリック

**オプション2: カスタムポリシー（推奨・最小権限）**

1. 「Create policy」をクリック
2. 「JSON」タブを選択
3. 以下のポリシーを貼り付け:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": [
        "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-sonnet-4-5-20250929-v1:0",
        "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-haiku-4-5-20251001-v1:0"
      ]
    }
  ]
}
```

4. 「Next」をクリック
5. ポリシー名: `BedrockInvokeOnlyPolicy`
6. 「Create policy」をクリック
7. ユーザー作成画面に戻り、作成したポリシーを選択

---

## アクセスキー作成

### 1. ユーザーの詳細画面を開く

1. IAM > Users > `bedrock-dev-user` をクリック
2. 「Security credentials」（セキュリティ認証情報）タブを選択

### 2. アクセスキーを作成

1. 「Create access key」（アクセスキーを作成）をクリック
2. ユースケースを選択:
   - ✅ 「Local code」（ローカルコード）を選択
3. 確認チェックボックスにチェック
4. 「Next」をクリック
5. 説明タグ（オプション）: `Portfolio Bedrock Development`
6. 「Create access key」をクリック

### 3. 認証情報を保存

**重要**: この画面は一度しか表示されません！

```
Access key ID: AKIA...（20文字）
Secret access key: wJalrXUtn...（40文字）
```

- 「Download .csv file」をクリックして保存
- または、メモ帳にコピー＆ペースト
- **絶対にGitにコミットしないこと！**

---

## ローカル環境設定

### 方法1: 環境変数ファイル（推奨）

1. プロジェクトルートの `.env` ファイルを編集:

```bash
# AWS Bedrock Configuration
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=AKIA...（あなたのアクセスキーID）
AWS_SECRET_ACCESS_KEY=wJalrXUtn...（あなたのシークレットキー）
```

2. `.env` が `.gitignore` に含まれていることを確認:

```bash
# .gitignore に以下が含まれているか確認
.env
.env.local
```

### 方法2: AWS CLI設定（オプション）

AWS CLIを使う場合:

```bash
# AWS CLIをインストール（まだの場合）
brew install awscli  # macOS
# または
pip install awscli

# 認証情報を設定
aws configure

# 入力を求められる:
AWS Access Key ID: AKIA...
AWS Secret Access Key: wJalrXUtn...
Default region name: us-east-1
Default output format: json
```

これで `~/.aws/credentials` に保存されます。

---

## 動作確認

### 1. Railsコンソールでテスト

```bash
# Railsコンソールを起動
bundle exec rails console
```

```ruby
# Bedrockクライアントを作成
client = Ai::BedrockClient.new

# 簡単なテスト（Haiku 4.5を使用）
model_id = 'anthropic.claude-haiku-4-5-20251001-v1:0'
prompt = 'こんにちは！簡単な自己紹介をしてください。'

result = client.invoke_model(model_id, prompt)
puts result[:content]
# => "こんにちは！私はClaudeです..."

puts "トークン使用量: #{result[:usage][:input_tokens] + result[:usage][:output_tokens]}"
# => "トークン使用量: 150"
```

### 2. RSpecでテスト

```bash
# AI関連のテストを実行
bundle exec rspec spec/services/ai/bedrock_client_spec.rb

# 全てのAIテストを実行
bundle exec rspec spec/services/ai/ spec/models/ai_*
```

### 3. エラーが出た場合

#### エラー1: `Aws::Errors::MissingCredentialsError`
```
原因: 認証情報が設定されていない
解決: .env ファイルを確認、AWS_ACCESS_KEY_ID と AWS_SECRET_ACCESS_KEY が正しいか
```

#### エラー2: `AccessDeniedException`
```
原因: IAMユーザーに権限がない
解決: IAMポリシーを確認、BedrockFullAccess または InvokeModel 権限があるか
```

#### エラー3: `ResourceNotFoundException`
```
原因: モデルアクセスが承認されていない
解決: Bedrock コンソールで Model access を確認
```

#### エラー4: `ValidationException: The provided model identifier is invalid`
```
原因: リージョンが間違っている、またはモデルIDが間違っている
解決: AWS_REGION=us-east-1 を確認、モデルIDを確認
```

---

## 本番環境設定

### EC2/ECS/Fargate の場合（推奨）

**IAMロールを使用**（アクセスキー不要）:

1. IAMロールを作成:
   - サービス: EC2 / ECS Task
   - ポリシー: `BedrockInvokeOnlyPolicy`（上記で作成したもの）

2. EC2インスタンスまたはECSタスクにロールをアタッチ

3. アプリケーションコードは自動的にロールを使用:
```ruby
# app/services/ai/bedrock_client.rb
# 本番環境では自動的にIAMロールを使用
credentials = if Rails.env.production?
  Aws::InstanceProfileCredentials.new  # IAMロールから自動取得
else
  Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
end
```

### Heroku/Render などの場合

環境変数を設定:
```bash
# Heroku の場合
heroku config:set AWS_REGION=us-east-1
heroku config:set AWS_ACCESS_KEY_ID=AKIA...
heroku config:set AWS_SECRET_ACCESS_KEY=wJalrXUtn...

# Render の場合
# ダッシュボードで Environment Variables に追加
```

---

## コスト管理

### 1. 予算アラートを設定

1. AWS Billing コンソールを開く
2. 「Budgets」を選択
3. 「Create budget」をクリック
4. 予算額を設定（例: $10/月）
5. アラートメールアドレスを設定

### 2. コスト見積もり

**Claude Haiku 4.5**（高速・高品質・推奨）:
- Input: $1.00 / 1M tokens
- Output: $5.00 / 1M tokens
- 特徴: Sonnet 4並みの性能、4-5倍速い

**Claude Sonnet 4.5**（最高品質）:
- Input: $3.00 / 1M tokens
- Output: $15.00 / 1M tokens
- 特徴: 最高性能、コーディング・推論に最適

**月間20記事の場合の試算（Claude 4.5シリーズ）**:
- 要約生成（Sonnet 4.5）: 20回 × $0.05 = $1.00
- タグ提案（Haiku 4.5）: 20回 × $0.03 = $0.60
- スラッグ生成（Haiku 4.5）: 20回 × $0.02 = $0.40
- SEO生成（Sonnet 4.5）: 20回 × $0.05 = $1.00
- **合計: 約$3.00/月**

**旧世代との比較**:
- Claude 3シリーズ: 約$2.40/月
- Claude 4.5シリーズ: 約$3.00/月（+$0.60、性能大幅向上）

### 3. 使用量監視

アプリケーション内で監視:
```ruby
# 今月の使用量を確認
Ai::UsageTracker.this_month
# => { totals: { cost: 2.35, requests: 80, tokens: 150000 } }

# 予算残高を確認
Ai::UsageTracker.remaining_budget(10.00)
# => 7.65
```

---

## セキュリティベストプラクティス

### ✅ やるべきこと

1. **アクセスキーを定期的にローテーション**（90日ごと）
2. **最小権限の原則**（必要な権限のみ付与）
3. **本番環境ではIAMロールを使用**
4. **アクセスキーをGitにコミットしない**
5. **CloudTrailでAPI呼び出しを監視**

### ❌ やってはいけないこと

1. ルートアカウントのアクセスキーを使用
2. アクセスキーをコードにハードコード
3. 公開リポジトリにアクセスキーをコミット
4. 不要な権限を付与（例: AdministratorAccess）

---

## トラブルシューティング

### Q1: モデルアクセスが承認されない

**A**: 
- リージョンを確認（us-east-1推奨）
- アカウントが有効か確認（支払い情報登録済み）
- 数分待ってリフレッシュ

### Q2: コストが予想より高い

**A**:
- `Ai::UsageTracker.this_month` で詳細確認
- 不要なリクエストがないか確認
- Haikuモデルを優先的に使用

### Q3: レート制限エラーが頻発

**A**:
- リトライロジックが動作しているか確認
- リクエスト頻度を下げる
- AWS Supportに制限緩和を依頼

### Q4: 本番環境で認証エラー

**A**:
- IAMロールがアタッチされているか確認
- ロールに正しいポリシーがあるか確認
- CloudWatch Logsでエラー詳細を確認

---

## 参考リンク

- [Amazon Bedrock 公式ドキュメント](https://docs.aws.amazon.com/bedrock/)
- [Claude API リファレンス](https://docs.anthropic.com/claude/reference/)
- [AWS SDK for Ruby](https://docs.aws.amazon.com/sdk-for-ruby/)
- [Bedrock 料金](https://aws.amazon.com/bedrock/pricing/)

---

## チェックリスト

設定完了の確認:

- [ ] AWSアカウント作成済み
- [ ] リージョンを us-east-1 に設定
- [ ] Bedrock でモデルアクセス承認済み（Claude Sonnet 4.5, Claude Haiku 4.5）
- [ ] IAMユーザー作成済み（bedrock-dev-user）
- [ ] IAMポリシー設定済み（BedrockInvokeOnlyPolicy）
- [ ] アクセスキー作成済み
- [ ] `.env` ファイルに認証情報設定済み
- [ ] `.gitignore` に `.env` 追加済み
- [ ] Railsコンソールで動作確認済み
- [ ] RSpecテストがパス
- [ ] 予算アラート設定済み（オプション）

全てチェックできたら、Week 2の実装に進めます！🎉
