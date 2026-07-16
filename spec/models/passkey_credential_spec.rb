require "rails_helper"

RSpec.describe PasskeyCredential, type: :model do
  let(:admin_user) { create(:admin_user) }

  describe "バリデーション" do
    it "有効なファクトリを持つ" do
      expect(build(:passkey_credential, admin_user: admin_user)).to be_valid
    end

    it "external_idは必須かつ一意" do
      existing = create(:passkey_credential, admin_user: admin_user)
      duplicate = build(:passkey_credential, admin_user: admin_user, external_id: existing.external_id)

      expect(build(:passkey_credential, external_id: nil)).not_to be_valid
      expect(duplicate).not_to be_valid
    end

    it "public_keyとnicknameは必須" do
      expect(build(:passkey_credential, public_key: nil)).not_to be_valid
      expect(build(:passkey_credential, nickname: "")).not_to be_valid
    end

    it "同一管理者内でnicknameは一意（区別がつかなくなるのを防ぐ）" do
      create(:passkey_credential, admin_user: admin_user, nickname: "iPhone")
      duplicate = build(:passkey_credential, admin_user: admin_user, nickname: "iPhone")

      expect(duplicate).not_to be_valid
    end

    it "1管理者につき最大10個まで登録できる" do
      create_list(:passkey_credential, 10, admin_user: admin_user)
      eleventh = build(:passkey_credential, admin_user: admin_user)

      expect(eleventh).not_to be_valid
      expect(eleventh.errors[:base].join).to include("上限")
    end
  end

  describe "#record_usage!" do
    it "sign_countとlast_used_atを更新する" do
      credential = create(:passkey_credential, admin_user: admin_user, sign_count: 5)

      credential.record_usage!(sign_count: 6)

      expect(credential.reload.sign_count).to eq(6)
      expect(credential.last_used_at).to be_present
    end

    it "sign_countの逆行（クローン検知）でエラーを発生させる" do
      # 認証器のカウンタが戻る = 秘密鍵が複製された疑い（WebAuthn仕様のクローン検知）
      credential = create(:passkey_credential, admin_user: admin_user, sign_count: 10)

      expect {
        credential.record_usage!(sign_count: 3)
      }.to raise_error(PasskeyCredential::CloneDetectedError)
    end

    it "sign_count=0の認証器（カウンタ非対応）は常に許可する" do
      credential = create(:passkey_credential, admin_user: admin_user, sign_count: 0)

      expect { credential.record_usage!(sign_count: 0) }.not_to raise_error
    end
  end

  describe "AdminUserとの関連" do
    it "admin_userの削除でパスキーも削除される" do
      credential = create(:passkey_credential, admin_user: admin_user)

      admin_user.destroy!

      expect(PasskeyCredential.exists?(credential.id)).to be false
    end

    it "AdminUser#webauthn_idは初回アクセス時に自動生成され永続化される" do
      expect(admin_user.webauthn_id).to be_present
      expect(admin_user.reload.webauthn_id).to eq(admin_user.webauthn_id)
    end
  end
end
