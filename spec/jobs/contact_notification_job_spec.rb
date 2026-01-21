require 'rails_helper'

RSpec.describe ContactNotificationJob, type: :job do
  let(:contact) { create(:contact) }

  it 'sends slack notification in non-production' do
    notifier = instance_double(SlackNotifier, send_notification: true)
    allow(SlackNotifier).to receive(:new).and_return(notifier)
    allow(Rails).to receive_message_chain(:env, :production?).and_return(false)

    described_class.new.perform(contact)

    expect(SlackNotifier).to have_received(:new).with(contact)
  end

  it 'sends emails in production' do
    notifier = instance_double(SlackNotifier, send_notification: true)
    allow(SlackNotifier).to receive(:new).and_return(notifier)
    allow(Rails).to receive_message_chain(:env, :production?).and_return(true)

    admin_mail = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
    user_mail = instance_double(ActionMailer::MessageDelivery, deliver_now: true)

    allow(ContactMailer).to receive(:admin_notification).and_return(admin_mail)
    allow(ContactMailer).to receive(:auto_reply).and_return(user_mail)

    described_class.new.perform(contact)

    expect(ContactMailer).to have_received(:admin_notification).with(contact)
    expect(ContactMailer).to have_received(:auto_reply).with(contact)
  end
end
