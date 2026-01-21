require 'rails_helper'

RSpec.describe SlackNotifier do
  let(:contact) { create(:contact, message: 'a' * 400) }
  let(:webhook_url) { 'https://hooks.slack.test' }

  around do |example|
    original = ENV['SLACK_WEBHOOK_URL']
    ENV['SLACK_WEBHOOK_URL'] = webhook_url
    example.run
    ENV['SLACK_WEBHOOK_URL'] = original
  end

  it 'sends a notification and records success' do
    response = instance_double(HTTParty::Response, success?: true)
    allow(HTTParty).to receive(:post).and_return(response)

    notifier = described_class.new(contact)

    expect { notifier.send_notification }.to change(SlackNotification, :count).by(1)
    expect(SlackNotification.last).to be_sent
  end

  it 'returns false when webhook is missing' do
    ENV['SLACK_WEBHOOK_URL'] = nil
    notifier = described_class.new(contact)

    expect(notifier.send_notification).to eq(false)
  end

  it 'records failure when request raises an error' do
    allow(HTTParty).to receive(:post).and_raise(StandardError, 'network error')

    notifier = described_class.new(contact)

    expect { notifier.send_notification }.to change(SlackNotification, :count).by(1)
    expect(SlackNotification.last).to be_failed
  end

  it 'truncates long messages in payload' do
    allow(HTTParty).to receive(:post).and_return(instance_double(HTTParty::Response, success?: true))

    notifier = described_class.new(contact)
    payload = notifier.send(:build_payload)

    message_field = payload[:attachments][0][:fields].find { |f| f[:title].include?('メッセージ') }
    expect(message_field[:value].length).to be <= 303
  end
end
