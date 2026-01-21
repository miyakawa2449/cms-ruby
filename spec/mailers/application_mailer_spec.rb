require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  it 'uses default from address' do
    mail = ContactMailer.admin_notification(create(:contact))

    expect(mail.from).to include(ENV.fetch('MAIL_FROM', 'noreply@example.test'))
  end
end
