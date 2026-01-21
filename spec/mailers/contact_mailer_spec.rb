require 'rails_helper'

RSpec.describe ContactMailer, type: :mailer do
  let(:contact) { create(:contact, subject: 'Hello', name: 'Tester', email: 'tester@example.com') }

  around do |example|
    original = ENV['ADMIN_EMAIL']
    ENV['ADMIN_EMAIL'] = 'admin@example.com'
    example.run
    ENV['ADMIN_EMAIL'] = original
  end

  it 'builds admin notification email' do
    mail = described_class.admin_notification(contact)

    expect(mail.to).to eq(['admin@example.com'])
    expect(mail.subject).to include('Hello')
    expect(mail.subject).to include('Tester')
  end

  it 'builds auto reply email' do
    mail = described_class.auto_reply(contact)

    expect(mail.to).to eq(['tester@example.com'])
    expect(mail.subject).to include('お問い合わせありがとうございます')
  end
end
