# AWS SES 設定の修正指示書

## 問題の概要

デプロイ時に以下のエラーが発生している：

```
LoadError: cannot load such file -- aws-sdk-ses (LoadError)
/rails/config/initializers/aws_ses.rb:2:in '<main>'
```

**原因:** Gemfile には `aws-sdk-sesv2`（v2）が入っているが、initializer では `aws-sdk-ses`（v1）を require しようとしている。これらは別のgemである。

## 修正方針

`aws-sdk-sesv2` は AWS 推奨の新しい API。Gemfile は正しいので、initializer を v2 に対応させる。

ActionMailer との統合は **SMTP 方式** を採用する（シンプルで信頼性が高い）。

## 修正するファイル

### 1. `config/initializers/aws_ses.rb`

以下の内容に置き換える：

```ruby
# frozen_string_literal: true

# AWS SES v2 SMTP Configuration for Production
# Note: Using SMTP delivery method with SES SMTP endpoint
# This is simpler and more reliable than direct API integration

if Rails.env.production?
  # Validate required environment variables
  required_vars = %w[AWS_SES_SMTP_USERNAME AWS_SES_SMTP_PASSWORD]
  missing_vars = required_vars.select { |var| ENV[var].blank? }
  
  if missing_vars.any?
    Rails.logger.warn "AWS SES SMTP credentials not configured. Missing: #{missing_vars.join(', ')}"
    Rails.logger.warn "Email delivery will be disabled."
  else
    Rails.application.configure do
      config.action_mailer.delivery_method = :smtp
      config.action_mailer.smtp_settings = {
        address: "email-smtp.#{ENV.fetch('AWS_SES_REGION', 'ap-northeast-1')}.amazonaws.com",
        port: 587,
        user_name: ENV.fetch('AWS_SES_SMTP_USERNAME'),
        password: ENV.fetch('AWS_SES_SMTP_PASSWORD'),
        authentication: :login,
        enable_starttls_auto: true
      }
      
      config.action_mailer.default_options = {
        from: ENV.fetch('MAIL_FROM', 'noreply@miyakawa.codes')
      }
      
      config.action_mailer.default_url_options = {
        host: ENV.fetch('APP_HOST', 'miyakawa.codes'),
        protocol: 'https'
      }
      
      config.action_mailer.perform_deliveries = true
      config.action_mailer.raise_delivery_errors = true
    end
    
    Rails.logger.info "AWS SES SMTP configured for region: #{ENV.fetch('AWS_SES_REGION', 'ap-northeast-1')}"
  end
end
```

### 2. `.env.example` に環境変数を追加

以下の環境変数を追加（既存のものは置き換え）：

```bash
# AWS SES SMTP Configuration
AWS_SES_REGION=ap-northeast-1
AWS_SES_SMTP_USERNAME=your_smtp_username
AWS_SES_SMTP_PASSWORD=your_smtp_password
MAIL_FROM=noreply@miyakawa.codes
APP_HOST=miyakawa.codes
```

### 3. Gemfile から不要な gem を削除（任意）

`aws-sdk-sesv2` は SMTP 方式では不要になるが、将来 SES API を直接使う可能性があれば残しておいてもよい。削除する場合：

```ruby
# 削除する行
gem "aws-sdk-sesv2", "~> 1.35"
```

削除後は `bundle install` と `Gemfile.lock` の更新が必要。

## 環境変数の取得方法（運用担当者向けメモ）

AWS SES SMTP 認証情報は IAM Access Key とは異なる。取得手順：

1. AWS Console → SES → SMTP Settings
2. 「Create SMTP Credentials」をクリック
3. IAM ユーザーが作成され、SMTP Username と Password が表示される
4. これを `AWS_SES_SMTP_USERNAME` と `AWS_SES_SMTP_PASSWORD` に設定

**注意:** SMTP Password は一度しか表示されないので必ず保存すること。

## 検証方法

修正後、以下を確認：

1. ローカルでビルドが通ること
   ```bash
   docker compose build
   ```

2. Rails console でメール設定を確認
   ```ruby
   Rails.application.config.action_mailer.delivery_method
   # => :smtp
   
   Rails.application.config.action_mailer.smtp_settings
   # => {address: "email-smtp.ap-northeast-1.amazonaws.com", ...}
   ```

3. 本番デプロイが成功すること

## 補足

旧環境変数（`AWS_SES_ACCESS_KEY_ID`, `AWS_SES_SECRET_ACCESS_KEY`）は SMTP 方式では使用しない。本番サーバーの環境変数を `AWS_SES_SMTP_USERNAME`, `AWS_SES_SMTP_PASSWORD` に置き換える必要がある。
