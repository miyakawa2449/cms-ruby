# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminPathMailer, type: :mailer do
  let(:admin_user) { create(:admin_user, email: "admin@example.com") }

  describe "#path_changed" do
    let(:mail) { described_class.path_changed(admin_user, "old-admin", "new-admin", "manual") }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Important] Admin URL Changed")
      expect(mail.to).to include(ENV.fetch("ADMIN_EMAIL", admin_user.email))
    end

    it "renders the body with path information" do
      expect(body).to include("old-admin")
      expect(body).to include("new-admin")
      expect(body).to include(admin_user.email)
    end
  end

  describe "#rotation_notification" do
    let(:next_rotation) { 1.day.from_now.iso8601 }
    let(:mail) { described_class.rotation_notification(admin_user, next_rotation) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Notice] Admin URL will be rotated in 24 hours")
      expect(mail.to).to include(ENV.fetch("ADMIN_EMAIL", admin_user.email))
    end

    it "renders the body with rotation time" do
      expect(body).to include(next_rotation)
      expect(body).to include(admin_user.email)
    end
  end

  describe "#emergency_rotation" do
    let(:reason) { "Suspicious access detected" }
    let(:mail) { described_class.emergency_rotation(admin_user, "old-path", "new-path", reason) }
    let(:body) { mail.text_part ? mail.text_part.body.decoded : mail.body.decoded }

    it "renders the headers" do
      expect(mail.subject).to eq("[Urgent] Emergency Admin URL Rotation Completed")
      expect(mail.to).to include(ENV.fetch("ADMIN_EMAIL", admin_user.email))
    end

    it "renders the body with rotation details" do
      expect(body).to include("old-path")
      expect(body).to include("new-path")
      expect(body).to include(reason)
    end
  end
end
