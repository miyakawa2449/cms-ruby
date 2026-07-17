# frozen_string_literal: true

require "rails_helper"

# S1-7 P2-3: TypeManager/ValueManagerをモデルへ吸収（CacheManagerのみ別クラスで残す）
RSpec.describe SiteSetting, type: :model do
  describe "#get_value / #update_value（テキスト設定）" do
    let(:setting) do
      described_class.create!(key: "site_title", setting_type: "text", value: "旧タイトル")
    end

    it "テキスト値を取得・更新できる" do
      expect(setting.get_value).to eq("旧タイトル")

      result = setting.update_value("新タイトル")

      expect(result[:valid]).to be true
      expect(setting.reload.get_value).to eq("新タイトル")
    end

    it "必須設定は空文字への更新を拒否する" do
      result = setting.update_value("")

      expect(result[:valid]).to be false
      expect(result[:errors]).to include("Value cannot be blank")
      expect(setting.reload.get_value).to eq("旧タイトル")
    end

    it "optional設定（gtm_id）は空文字への更新を許可する" do
      gtm = described_class.create!(key: "gtm_id", setting_type: "text", value: "GTM-XXXX")

      result = gtm.update_value("")

      expect(result[:valid]).to be true
      expect(gtm.reload.get_value).to eq("")
    end

    it "1000文字を超える値を拒否する" do
      result = setting.update_value("a" * 1001)

      expect(result[:valid]).to be false
    end

    it "未定義のキーはエラーを返す" do
      unknown = described_class.new(key: "unknown_key", setting_type: "text")

      result = unknown.update_value("value")

      expect(result[:valid]).to be false
      expect(result[:errors]).to include("Setting not found")
    end
  end

  describe "#get_value（画像設定）" do
    it "画像設定はattachmentを返す" do
      setting = described_class.create!(key: "logo", setting_type: "image")
      setting.image_value.attach(io: StringIO.new("img"), filename: "logo.png", content_type: "image/png")

      expect(setting.get_value).to eq(setting.image_value)
    end
  end

  describe ".default_for" do
    it "設定のデフォルト値を返す" do
      expect(described_class.default_for(:site_title)).to be_present
    end

    it "未知の設定はnilを返す" do
      expect(described_class.default_for(:unknown)).to be_nil
    end
  end

  describe "設定ごとのクラスメソッド（SiteSetting.site_title等）" do
    it "キャッシュ経由で設定レコードを返す" do
      setting = described_class.create!(key: "site_title", setting_type: "text", value: "タイトル")
      SiteSettingCacheManager.clear_cache

      expect(described_class.site_title).to eq(setting)
    end
  end

  describe "バリデーション" do
    it "setting_typeはtext/image/fileのみ許可する" do
      setting = described_class.new(key: "site_title", setting_type: "invalid")

      expect(setting).not_to be_valid
    end
  end
end
