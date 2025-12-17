if Rails.env.production?
  require 'aws-sdk-ses'
  
  # AWS SES設定
  Aws.config.update({
    region: ENV.fetch('AWS_SES_REGION', 'ap-northeast-1'),
    credentials: Aws::Credentials.new(
      ENV.fetch('AWS_SES_ACCESS_KEY_ID'),
      ENV.fetch('AWS_SES_SECRET_ACCESS_KEY')
    )
  })
  
  # Action Mailer設定
  ActionMailer::Base.add_delivery_method :ses, 
    AWS::SES::Base,
    server: ENV.fetch('AWS_SES_REGION', 'ap-northeast-1')
  
  # 本番環境のメール設定
  Rails.application.configure do
    config.action_mailer.delivery_method = :ses
    config.action_mailer.default_options = {
      from: ENV.fetch('MAIL_FROM', 'noreply@miyakawa.codes')
    }
    
    # URL生成用のホスト設定
    config.action_mailer.default_url_options = {
      host: ENV.fetch('APP_HOST', 'miyakawa.codes'),
      protocol: 'https'
    }
    
    config.action_mailer.perform_deliveries = true
    config.action_mailer.raise_delivery_errors = true
    
    Rails.logger.info "AWS SES configured for region: #{ENV.fetch('AWS_SES_REGION', 'ap-northeast-1')}"
    Rails.logger.info "Mail from: #{ENV.fetch('MAIL_FROM', 'noreply@miyakawa.codes')}"
  end
end