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
end
