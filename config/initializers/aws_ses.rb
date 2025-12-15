# AWS SES Configuration for ActionMailer (using SMTP)
if Rails.env.production? && ENV['AWS_ACCESS_KEY_ID'].present?
  ActionMailer::Base.smtp_settings = {
    address:              'email-smtp.us-east-1.amazonaws.com',
    port:                 587,
    domain:               ENV['APP_HOST'] || 'miyakawa.codes',
    user_name:            ENV['AWS_ACCESS_KEY_ID'],
    password:             ENV['AWS_SECRET_ACCESS_KEY'],
    authentication:       :plain,
    enable_starttls_auto: true
  }
end