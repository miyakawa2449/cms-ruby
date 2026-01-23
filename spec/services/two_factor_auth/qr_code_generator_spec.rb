# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactorAuth::QrCodeGenerator do
  let(:admin_user) { create(:admin_user) }

  before do
    admin_user.otp_secret = AdminUser.generate_otp_secret
    admin_user.save!
  end

  describe "#generate" do
    subject { described_class.new(admin_user).generate }

    it "returns a data URL for a PNG image" do
      expect(subject).to start_with("data:image/png;base64,")
    end

    it "contains valid Base64 data" do
      base64_data = subject.sub("data:image/png;base64,", "")
      expect { Base64.strict_decode64(base64_data) }.not_to raise_error
    end

    context "when OTP secret is not set" do
      before do
        admin_user.otp_secret = nil
        admin_user.save!
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#generate_svg" do
    subject { described_class.new(admin_user).generate_svg }

    it "returns an SVG string" do
      expect(subject).to include("<svg")
      expect(subject).to include("</svg>")
    end

    context "when OTP secret is not set" do
      before do
        admin_user.otp_secret = nil
        admin_user.save!
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#provisioning_uri" do
    subject { described_class.new(admin_user).provisioning_uri }

    it "returns a valid otpauth URI" do
      expect(subject).to start_with("otpauth://totp/")
    end

    it "includes the admin user email" do
      expect(subject).to include(CGI.escape(admin_user.email))
    end

    it "includes the issuer" do
      expect(subject).to include("issuer=Portfolio%20Site")
    end

    it "includes the secret" do
      expect(subject).to include("secret=")
    end
  end

  describe "#secret_key" do
    subject { described_class.new(admin_user).secret_key }

    it "returns the OTP secret" do
      expect(subject).to eq(admin_user.otp_secret)
    end
  end
end
