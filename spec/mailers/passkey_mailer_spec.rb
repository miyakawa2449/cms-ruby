# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasskeyMailer, type: :mailer do
  let(:admin_user) { create(:admin_user) }

  def decoded_body(mail)
    (mail.html_part || mail.text_part || mail).decoded
  end

  describe "#registered" do
    it "登録通知を本人宛に送り、ニックネームを本文に含める" do
      mail = described_class.registered(admin_user, "MacBook")

      expect(mail.to).to eq([ admin_user.email ])
      expect(mail.subject).to include("パスキーが登録されました")
      expect(decoded_body(mail)).to include("MacBook")
    end
  end

  describe "#removed" do
    it "削除通知を本人宛に送る" do
      mail = described_class.removed(admin_user, "iPhone")

      expect(mail.to).to eq([ admin_user.email ])
      expect(mail.subject).to include("パスキーが削除されました")
      expect(decoded_body(mail)).to include("iPhone")
    end
  end

  describe "#clone_detected" do
    it "クローン検知の警告を本人宛に送る" do
      mail = described_class.clone_detected(admin_user, "疑わしい鍵")

      expect(mail.to).to eq([ admin_user.email ])
      expect(mail.subject).to include("複製の疑い")
      expect(decoded_body(mail)).to include("疑わしい鍵")
    end
  end
end
