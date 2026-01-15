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
      region: ENV.fetch("AWS_SES_REGION", "ap-northeast-1"),
      credentials: Aws::Credentials.new(
        ENV.fetch("AWS_SES_ACCESS_KEY_ID"),
        ENV.fetch("AWS_SES_SECRET_ACCESS_KEY")
      )
    )

    # ActionMailer で SES v2 を使用
    Rails.application.configure do
      config.action_mailer.delivery_method = :sesv2

      config.action_mailer.default_options = {
        from: ENV.fetch("MAIL_FROM", "noreply@miyakawa.codes")
      }

      config.action_mailer.default_url_options = {
        host: ENV.fetch("APP_HOST", "miyakawa.codes"),
        protocol: "https"
      }

      config.action_mailer.perform_deliveries = true
      config.action_mailer.raise_delivery_errors = true
    end

    Rails.logger.info "AWS SES v2 API configured for region: #{ENV.fetch('AWS_SES_REGION', 'ap-northeast-1')}"
    Rails.logger.info "Mail from: #{ENV.fetch('MAIL_FROM', 'noreply@miyakawa.codes')}"
  end
end
