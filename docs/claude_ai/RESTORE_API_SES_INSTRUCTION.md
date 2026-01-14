# AWS SES v2 API方式への復旧指示書

## 概要

現在 SMTP 方式に変更されてしまった `aws_ses.rb` を、元の計画通り **API 方式（aws-sdk-sesv2 + IAM credentials）** に戻す。

## 修正内容

### 1. Gemfile に aws-sdk-rails を追加

`aws-sdk-rails` gem を追加すると、ActionMailer で `:ses` や `:sesv2` を delivery_method として使える。

```ruby
# AWS SES for email delivery
gem "aws-sdk-sesv2", "~> 1.35"
gem "aws-sdk-rails", "~> 4.0"
```

その後 `bundle install` を実行。

### 2. `config/initializers/aws_ses.rb` を以下に置き換え

```ruby
# frozen_string_literal: true

# AWS SES v2 API Configuration for Production
# Using aws-sdk-sesv2 with IAM credentials

if Rails.env.production?
  required_vars = %w[AWS_SES_ACCESS_KEY_ID AWS_SES_SECRET_ACCESS_KEY]
  missing_vars = required_vars.select { |var| ENV[var].blank? }

  if missing_vars.any?
    Rails.logger.warn "AWS SES credentials not configured. Missing: #{missing_vars.join(', ')}"
    Rails.logger.warn "Email delivery will be disabled."
  else
    # AWS SDK の設定
    Aws.config.update(
      region: ENV.fetch('AWS_SES_REGION', 'ap-northeast-1'),
      credentials: Aws::Credentials.new(
        ENV.fetch('AWS_SES_ACCESS_KEY_ID'),
        ENV.fetch('AWS_SES_SECRET_ACCESS_KEY')
      )
    )

    # ActionMailer で SES v2 を使用
    Rails.application.configure do
      config.action_mailer.delivery_method = :sesv2

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

    Rails.logger.info "AWS SES v2 API configured for region: #{ENV.fetch('AWS_SES_REGION', 'ap-northeast-1')}"
    Rails.logger.info "Mail from: #{ENV.fetch('MAIL_FROM', 'noreply@miyakawa.codes')}"
  end
end
```

### 3. 必要な環境変数（既存のものを使用）

```bash
AWS_SES_ACCESS_KEY_ID=AKIA...
AWS_SES_SECRET_ACCESS_KEY=...
AWS_SES_REGION=ap-northeast-1
MAIL_FROM=noreply@miyakawa.codes
ADMIN_EMAIL=contact@miyakawa.codes
APP_HOST=miyakawa.codes
```

## デプロイ後の確認

### 1. 設定の確認

```bash
docker exec -it portfolio-prod-portfolio-web-1 bin/rails runner "puts ActionMailer::Base.delivery_method"
# => sesv2
```

### 2. 失敗したジョブの再実行

```bash
docker exec -it portfolio-prod-portfolio-worker-1 bin/rails runner "
  failed = SolidQueue::FailedExecution.count
  puts \"Failed jobs: #{failed}\"
  SolidQueue::FailedExecution.all.each { |f| f.job.retry }
  puts 'All failed jobs retried'
"
```

### 3. テストメール送信

```bash
docker exec -it portfolio-prod-portfolio-web-1 bin/rails runner "
  ContactMailer.admin_notification(Contact.last).deliver_now
  puts 'Test email sent!'
"
```

## 補足: aws-sdk-rails について

- GitHub: https://github.com/aws/aws-sdk-rails
- `delivery_method :sesv2` を使うと、内部で `Aws::SESV2::Client` を使用してメール送信
- IAM credentials で認証
- SES API v2 の全機能を利用可能
