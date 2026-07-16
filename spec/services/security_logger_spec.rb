require "rails_helper"

RSpec.describe SecurityLogger do
  let(:user) { build_stubbed(:admin_user, id: 1, email: "admin@example.com") }
  let(:request) { instance_double(ActionDispatch::Request, remote_ip: "1.2.3.4", user_agent: "TestAgent", path: "/admin") }

  it "logs login success" do
    expect(Rails.logger).to receive(:info).with(/\[SECURITY\].*login_success/)
    described_class.log_login_success(user, request)
  end

  it "logs login failure" do
    expect(Rails.logger).to receive(:info).with(/\[SECURITY\].*login_failure/)
    described_class.log_login_failure("admin@example.com", request)
  end

  it "logs logout" do
    expect(Rails.logger).to receive(:info).with(/\[SECURITY\].*logout/)
    described_class.log_logout(user, request)
  end

  it "logs account locked with warning" do
    expect(Rails.logger).to receive(:warn).with(/\[SECURITY\].*account_locked/)
    described_class.log_account_locked(user, request)
  end

  it "logs account unlocked" do
    expect(Rails.logger).to receive(:info).with(/\[SECURITY\].*account_unlocked/)
    described_class.log_account_unlocked(user, request)
  end

  it "logs unauthorized access" do
    expect(Rails.logger).to receive(:warn).with(/\[SECURITY\].*unauthorized_access/)
    described_class.log_unauthorized_access("/admin", request)
  end

  it "logs rate limit exceeded" do
    expect(Rails.logger).to receive(:warn).with(/\[SECURITY\].*rate_limit_exceeded/)
    described_class.log_rate_limit_exceeded("logins/ip", request)
  end

  it "includes discriminator in rate limit log" do
    expect(Rails.logger).to receive(:warn).with(/logins\/ip/)
    described_class.log_rate_limit_exceeded("logins/ip", request)
  end

  it "handles nil request gracefully" do
    expect(Rails.logger).to receive(:info).with(/\[SECURITY\].*logout/)
    described_class.log_logout(user, nil)
  end

  it "includes ip and user agent in log data" do
    expect(Rails.logger).to receive(:info) do |message|
      payload = message.sub("[SECURITY] ", "")
      data = JSON.parse(payload)
      expect(data["ip"]).to eq("1.2.3.4")
      expect(data["user_agent"]).to eq("TestAgent")
    end

    described_class.log_login_success(user, request)
  end

  describe "イベントのDB永続化（P0-4）" do
    it "ログイン失敗をSecurityEventとして保存する" do
      expect {
        described_class.log_login_failure("admin@example.com", request)
      }.to change(SecurityEvent, :count).by(1)

      event = SecurityEvent.last
      expect(event.event_type).to eq("login_failure")
      expect(event.email).to eq("admin@example.com")
      expect(event.ip).to eq("1.2.3.4")
      expect(event.user_agent).to eq("TestAgent")
      expect(event.occurred_at).to be_present
    end

    it "不正アクセスをパス付きで保存する" do
      expect {
        described_class.log_unauthorized_access("/admin/secret", request)
      }.to change(SecurityEvent.of_type("unauthorized_access"), :count).by(1)

      expect(SecurityEvent.last.path).to eq("/admin/secret")
    end

    it "CSRFエラーを保存する" do
      csrf_request = instance_double(
        ActionDispatch::Request,
        remote_ip: "1.2.3.4", user_agent: "TestAgent", fullpath: "/contacts"
      )

      expect {
        described_class.log_csrf_error(csrf_request)
      }.to change(SecurityEvent.of_type("csrf_error"), :count).by(1)
    end

    it "ブロックされたリクエストを保存する" do
      expect {
        described_class.log_request_blocked("block suspicious requests", request)
      }.to change(SecurityEvent.of_type("request_blocked"), :count).by(1)

      expect(SecurityEvent.last.metadata["discriminator"]).to eq("block suspicious requests")
    end

    it "DB保存に失敗してもログ出力は行われ例外を握りつぶす" do
      allow(SecurityEvent).to receive(:create!).and_raise(ActiveRecord::StatementInvalid, "DB down")

      expect(Rails.logger).to receive(:info).with(/\[SECURITY\].*login_failure/)
      expect(Rails.logger).to receive(:error).with(/イベントのDB保存に失敗/)

      expect {
        described_class.log_login_failure("admin@example.com", request)
      }.not_to raise_error
    end

    it "高頻度イベントは同一IP・同一種別を1分間重複排除する" do
      # test環境のRails.cacheはnull_storeのためMemoryStoreに差し替えて検証
      memory_store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_store)

      expect {
        described_class.log_rate_limit_exceeded("logins/ip", request)
        described_class.log_rate_limit_exceeded("logins/ip", request)
      }.to change(SecurityEvent, :count).by(1)
    end

    it "低頻度イベントは重複排除しない" do
      memory_store = ActiveSupport::Cache::MemoryStore.new
      allow(Rails).to receive(:cache).and_return(memory_store)

      expect {
        described_class.log_login_failure("admin@example.com", request)
        described_class.log_login_failure("admin@example.com", request)
      }.to change(SecurityEvent, :count).by(2)
    end
  end
end
