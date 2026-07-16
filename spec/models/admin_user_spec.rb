# frozen_string_literal: true

require "rails_helper"

RSpec.describe AdminUser, type: :model do
  let(:admin_user) { create(:admin_user) }

  describe "associations" do
    it { should have_many(:published_section_contents).class_name("SectionContent").with_foreign_key(:published_by).dependent(:nullify) }
    it { should have_many(:articles).dependent(:destroy) }
    it { should have_many(:ai_generations).dependent(:nullify) }
  end

  describe "validations" do
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe "2FA Methods" do
    describe "#enable_two_factor!" do
      it "generates an OTP secret" do
        admin_user.enable_two_factor!
        expect(admin_user.otp_secret).to be_present
      end

      it "sets otp_required_for_login to true" do
        admin_user.enable_two_factor!
        expect(admin_user.otp_required_for_login).to be true
      end

      it "sets otp_enabled_at timestamp" do
        admin_user.enable_two_factor!
        expect(admin_user.otp_enabled_at).to be_present
      end
    end

    describe "#disable_two_factor!" do
      before do
        admin_user.enable_two_factor!
        admin_user.generate_otp_backup_codes!
      end

      it "clears the OTP secret" do
        admin_user.disable_two_factor!
        expect(admin_user.otp_secret).to be_nil
      end

      it "sets otp_required_for_login to false" do
        admin_user.disable_two_factor!
        expect(admin_user.otp_required_for_login).to be false
      end

      it "clears otp_enabled_at" do
        admin_user.disable_two_factor!
        expect(admin_user.otp_enabled_at).to be_nil
      end

      it "clears backup codes" do
        admin_user.disable_two_factor!
        expect(admin_user.otp_backup_codes).to be_empty
      end
    end

    describe "#two_factor_enabled?" do
      it "returns false when 2FA is not enabled" do
        expect(admin_user.two_factor_enabled?).to be false
      end

      it "returns true when 2FA is enabled" do
        admin_user.enable_two_factor!
        expect(admin_user.two_factor_enabled?).to be true
      end
    end

    describe "#generate_otp_backup_codes!" do
      it "generates 10 backup codes" do
        codes = admin_user.generate_otp_backup_codes!
        expect(codes.size).to eq(10)
      end

      it "returns plain text codes" do
        codes = admin_user.generate_otp_backup_codes!
        codes.each do |code|
          expect(code).to match(/\A[A-F0-9]{10}\z/)
        end
      end

      it "stores hashed versions of the codes" do
        codes = admin_user.generate_otp_backup_codes!
        expect(admin_user.otp_backup_codes.size).to eq(10)
        expect(admin_user.otp_backup_codes.first).not_to eq(codes.first)
      end
    end

    describe "#validate_backup_code" do
      let!(:backup_codes) { admin_user.generate_otp_backup_codes! }

      it "validates a correct backup code" do
        expect(admin_user.validate_backup_code(backup_codes.first)).to be true
      end

      it "validates a correct backup code (case insensitive)" do
        expect(admin_user.validate_backup_code(backup_codes.first.downcase)).to be true
      end

      it "returns false for an invalid backup code" do
        expect(admin_user.validate_backup_code("invalid")).to be false
      end

      it "returns false for a blank backup code" do
        expect(admin_user.validate_backup_code("")).to be false
        expect(admin_user.validate_backup_code(nil)).to be false
      end

      it "removes the used backup code" do
        admin_user.validate_backup_code(backup_codes.first)
        expect(admin_user.otp_backup_codes.size).to eq(9)
      end

      it "does not allow reusing the same backup code" do
        admin_user.validate_backup_code(backup_codes.first)
        expect(admin_user.validate_backup_code(backup_codes.first)).to be false
      end
    end

    describe "#backup_codes_count" do
      it "returns 0 when no backup codes exist" do
        expect(admin_user.backup_codes_count).to eq(0)
      end

      it "returns the correct count" do
        admin_user.generate_otp_backup_codes!
        expect(admin_user.backup_codes_count).to eq(10)
      end
    end

    describe "#validate_and_consume_otp!" do
      it "accepts a backup code when OTP verification fails" do
        codes = admin_user.generate_otp_backup_codes!
        expect(admin_user.validate_and_consume_otp!(codes.first)).to be true
      end

      it "sends a notification email when a backup code is used" do
        # 旧verify画面にあった通知を実際のログイン経路に移植（S1-5d）
        codes = admin_user.generate_otp_backup_codes!

        expect {
          admin_user.validate_and_consume_otp!(codes.first)
        }.to have_enqueued_mail(TwoFactorAuthMailer, :backup_code_used)
      end

      it "does not send email for invalid codes" do
        admin_user.generate_otp_backup_codes!

        expect {
          admin_user.validate_and_consume_otp!("invalid-code")
        }.not_to have_enqueued_mail(TwoFactorAuthMailer, :backup_code_used)
      end
    end
  end
end
