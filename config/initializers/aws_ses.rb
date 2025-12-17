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