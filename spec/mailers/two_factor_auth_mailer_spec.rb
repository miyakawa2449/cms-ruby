# frozen_string_literal: true

require "rails_helper"

RSpec.describe TwoFactorAuthMailer, type: :mailer do
  let(:admin_user) { create(:admin_user, email: "admin@example.com") }

  describe "#enabled" do
    let(:mail) { described_class.enabled(admin_user) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Security] Two-Factor Authentication Enabled")
      expect(mail.to).to include(ENV.fetch("ADMIN_EMAIL", admin_user.email))
    end

    it "renders the body with account details" do
      expect(body).to include(admin_user.email)
      expect(body).to include("二要素認証")
    end

    it "includes important security notes" do
      expect(body).to include("バックアップコード")
    end
  end

  describe "#disabled" do
    let(:mail) { described_class.disabled(admin_user) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Important] Two-Factor Authentication Disabled")
    end

    it "renders the body with warning message" do
      expect(body).to include(admin_user.email)
      expect(body).to include("無効")
    end
  end

  describe "#backup_codes_regenerated" do
    let(:mail) { described_class.backup_codes_regenerated(admin_user) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Security] 2FA Backup Codes Regenerated")
    end

    it "renders the body with regeneration details" do
      expect(body).to include(admin_user.email)
      expect(body).to include("バックアップコード")
    end
  end

  describe "#backup_code_used" do
    let(:mail) { described_class.backup_code_used(admin_user, 5) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Security] 2FA Backup Code Used - 5 codes remaining")
    end

    it "renders the body with remaining codes count" do
      expect(body).to include(admin_user.email)
      expect(body).to include("5")
    end

    context "when remaining codes is low" do
      let(:mail) { described_class.backup_code_used(admin_user, 2) }
      let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

      it "includes warning message" do
        expect(body).to include("注意")
        expect(body).to include("2")
      end
    end
  end
end
