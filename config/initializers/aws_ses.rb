# frozen_string_literal: true

# AWS SES v2 API Configuration for Production
# Using aws-sdk-sesv2 with IAM credentials
#
# 重要: Aws.config.update() はグローバルに認証情報を設定するため、
# S3やBedrockなど他のAWSサービスのクライアントに干渉します。
# SES専用の認証情報は sesv2_settings でスコープして渡します。

if Rails.env.production?
  required_vars = %w[AWS_SES_ACCESS_KEY_ID AWS_SES_SECRET_ACCESS_KEY]
  missing_vars = required_vars.select { |var| ENV[var].blank? }

  if missing_vars.any?
    Rails.logger.warn "AWS SES credentials not configured. Missing: #{missing_vars.join(', ')}"
    Rails.logger.warn "Email delivery will be disabled."
  else
    ses_region = ENV.fetch("AWS_SES_REGION", "ap-northeast-1")

    # SESクライアントにのみ認証情報をスコープ（他のAWSサービスに干渉しない）
    Aws.config[:sesv2] = {
      region: ses_region,
      credentials: Aws::Credentials.new(
        ENV.fetch("AWS_SES_ACCESS_KEY_ID"),
        ENV.fetch("AWS_SES_SECRET_ACCESS_KEY")
      )
    }

    Rails.application.configure do
      config.action_mailer.delivery_method = :sesv2

      config.action_mailer.default_options = {
        from: ENV.fetch("MAIL_FROM", "noreply@example.test")
      }

      config.action_mailer.default_url_options = {
        host: ENV.fetch("APP_HOST", "example.test"),
        protocol: "https"
      }

      config.action_mailer.perform_deliveries = true
      config.action_mailer.raise_delivery_errors = true
    end

    Rails.logger.info "AWS SES v2 configured for region: #{ses_region} (scoped credentials, no global Aws.config)"
    Rails.logger.info "Mail from: #{ENV.fetch('MAIL_FROM', 'noreply@example.test')}"
  end
end
