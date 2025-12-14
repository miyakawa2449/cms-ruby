# AWS SES Configuration for ActionMailer
require 'aws-sdk-sesv2'

if Rails.env.production?
  ActionMailer::Base.add_delivery_method :aws_ses, ActionMailer::Base::AWSDeliveryMethod, {
    region: ENV['AWS_SES_REGION'] || 'us-east-1',
    access_key_id: ENV['AWS_SES_ACCESS_KEY_ID'],
    secret_access_key: ENV['AWS_SES_SECRET_ACCESS_KEY']
  }
end

# Custom AWS SES Delivery Method
class ActionMailer::Base::AWSDeliveryMethod
  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    ses_client = Aws::SESV2::Client.new(
      region: @settings[:region],
      access_key_id: @settings[:access_key_id],
      secret_access_key: @settings[:secret_access_key]
    )

    ses_client.send_email({
      from_email_address: mail.from.first,
      destination: {
        to_addresses: mail.to
      },
      content: {
        simple: {
          subject: {
            data: mail.subject,
            charset: 'UTF-8'
          },
          body: {
            text: {
              data: mail.body.to_s,
              charset: 'UTF-8'
            }
          }
        }
      }
    })
  end
end