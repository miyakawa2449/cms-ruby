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

  describe 'instance methods (contact notifications)' do
    it 'returns false when contact is nil' do
      notifier = described_class.new(nil)

      expect(notifier.send_notification).to eq(false)
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

      message_field = payload[:attachments][0][:fields].find { |f| f[:title].include?('Message') }
      expect(message_field[:value].length).to be <= 303
    end
  end

  describe '.enabled?' do
    it 'returns true when webhook URL is set' do
      expect(described_class.enabled?).to be true
    end

    it 'returns false when webhook URL is not set' do
      ENV['SLACK_WEBHOOK_URL'] = nil
      expect(described_class.enabled?).to be false
    end
  end

  describe '.notify_2fa_changed' do
    let(:admin_user) { create(:admin_user) }

    it 'sends notification when 2FA is enabled' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(HTTParty).to receive(:post).and_return(response)

      result = described_class.notify_2fa_changed(admin_user, 'enabled')

      expect(result).to be true
      expect(HTTParty).to have_received(:post).with(
        webhook_url,
        hash_including(headers: { "Content-Type" => "application/json" })
      )
    end

    it 'sends notification when 2FA is disabled' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(HTTParty).to receive(:post).and_return(response)

      result = described_class.notify_2fa_changed(admin_user, 'disabled')

      expect(result).to be true
    end

    it 'returns false when webhook is not configured' do
      ENV['SLACK_WEBHOOK_URL'] = nil
      result = described_class.notify_2fa_changed(admin_user, 'enabled')

      expect(result).to be false
    end

    it 'returns false when admin user is nil' do
      result = described_class.notify_2fa_changed(nil, 'enabled')

      expect(result).to be false
    end

    it 'returns false when action is blank' do
      result = described_class.notify_2fa_changed(admin_user, '')

      expect(result).to be false
    end
  end

  describe '.notify_admin_path_changed' do
    let(:admin_user) { create(:admin_user) }

    it 'sends notification for manual path change' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(HTTParty).to receive(:post).and_return(response)

      result = described_class.notify_admin_path_changed(admin_user, 'old-path', 'new-path', 'manual')

      expect(result).to be true
    end

    it 'creates a slack notification record on success' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(HTTParty).to receive(:post).and_return(response)

      expect {
        described_class.notify_admin_path_changed(admin_user, 'old-path', 'new-path', 'manual')
      }.to change(SlackNotification, :count).by(1)

      expect(SlackNotification.last).to be_sent
    end

    it 'sends notification for emergency rotation' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(HTTParty).to receive(:post).and_return(response)

      result = described_class.notify_admin_path_changed(admin_user, 'old-path', 'new-path', 'emergency')

      expect(result).to be true
    end

    it 'returns false when webhook is not configured' do
      ENV['SLACK_WEBHOOK_URL'] = nil
      result = described_class.notify_admin_path_changed(admin_user, 'old', 'new', 'manual')

      expect(result).to be false
    end

    it 'returns false when admin user is nil' do
      result = described_class.notify_admin_path_changed(nil, 'old', 'new', 'manual')

      expect(result).to be false
    end

    it 'returns false when paths are blank' do
      result = described_class.notify_admin_path_changed(admin_user, '', 'new', 'manual')

      expect(result).to be false
    end
  end

  describe '.notify_backup_status' do
    let(:backup_log) do
      double('BackupLog',
        id: 1,
        backup_type: 'daily',
        status: 'success',
        file_size: 1024 * 1024 * 10,
        error_message: nil,
        created_at: Time.current,
        class: Class.new { def self.name; 'BackupLog'; end }
      )
    end

    it 'sends notification for successful backup' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(HTTParty).to receive(:post).and_return(response)

      result = described_class.notify_backup_status(backup_log)

      expect(result).to be true
    end

    it 'sends notification for failed backup' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(HTTParty).to receive(:post).and_return(response)
      failed_log = double('BackupLog',
        id: 2,
        backup_type: 'daily',
        status: 'failed',
        file_size: nil,
        error_message: 'Connection timeout',
        created_at: Time.current,
        class: Class.new { def self.name; 'BackupLog'; end }
      )

      result = described_class.notify_backup_status(failed_log)

      expect(result).to be true
    end

    it 'returns false when webhook is not configured' do
      ENV['SLACK_WEBHOOK_URL'] = nil
      result = described_class.notify_backup_status(backup_log)

      expect(result).to be false
    end

    it 'returns false when backup log is nil' do
      result = described_class.notify_backup_status(nil)

      expect(result).to be false
    end
  end

  describe '.notify_security_issue' do
    let(:audit_log) do
      double('SecurityAuditLog',
        id: 1,
        audit_type: 'brakeman',
        status: 'warning',
        issues_count: 3,
        created_at: Time.current,
        class: Class.new { def self.name; 'SecurityAuditLog'; end }
      )
    end

    it 'sends notification for security issues' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(HTTParty).to receive(:post).and_return(response)

      result = described_class.notify_security_issue(audit_log)

      expect(result).to be true
    end

    it 'returns false when webhook is not configured' do
      ENV['SLACK_WEBHOOK_URL'] = nil
      result = described_class.notify_security_issue(audit_log)

      expect(result).to be false
    end

    it 'returns false when audit log is nil' do
      result = described_class.notify_security_issue(nil)

      expect(result).to be false
    end
  end

  describe '.notify_health_check_alert' do
    it 'sends notification for critical health check' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(HTTParty).to receive(:post).and_return(response)

      result = described_class.notify_health_check_alert('database', 'critical', { response_time: 5000 })

      expect(result).to be true
    end

    it 'sends notification for warning health check' do
      response = instance_double(HTTParty::Response, success?: true)
      allow(HTTParty).to receive(:post).and_return(response)

      result = described_class.notify_health_check_alert('disk', 'warning', { used_percent: 85 })

      expect(result).to be true
    end

    it 'returns false when webhook is not configured' do
      ENV['SLACK_WEBHOOK_URL'] = nil
      result = described_class.notify_health_check_alert('database', 'critical', {})

      expect(result).to be false
    end

    it 'returns false when check_type is blank' do
      result = described_class.notify_health_check_alert('', 'critical', {})

      expect(result).to be false
    end

    it 'returns false when status is blank' do
      result = described_class.notify_health_check_alert('database', '', {})

      expect(result).to be false
    end
  end
end
