# frozen_string_literal: true

require "rails_helper"

RSpec.describe GtmHelper, type: :helper do
  def create_gtm_setting(value)
    SiteSetting.find_or_initialize_by(key: "gtm_id").tap do |s|
      s.setting_type = "text"
      s.value = value
      s.save!
    end
    SiteSettingCacheManager.clear_cache
  end

  context "GTM IDが設定されている場合" do
    before { create_gtm_setting("GTM-TEST123") }

    it "gtm_installed?がtrueを返す" do
      expect(helper.gtm_installed?).to be true
    end

    it "headタグにGTM IDを埋め込む" do
      allow(helper).to receive(:content_security_policy_nonce).and_return("nonce123")

      html = helper.gtm_head_tag

      expect(html).to include("GTM-TEST123")
      expect(html).to include("googletagmanager.com")
    end

    it "bodyタグ（noscript）にGTM IDを埋め込む" do
      html = helper.gtm_body_tag

      expect(html).to include("noscript")
      expect(html).to include("GTM-TEST123")
    end
  end

  context "GTM IDが未設定（空）の場合" do
    before { create_gtm_setting("") }

    it "gtm_installed?がfalseを返しタグを出力しない" do
      expect(helper.gtm_installed?).to be false
      expect(helper.gtm_head_tag).to be_nil
      expect(helper.gtm_body_tag).to be_nil
    end
  end
end
