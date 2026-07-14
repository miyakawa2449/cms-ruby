require "rails_helper"

# 監査レポート（docs/analysis/generic_cms_audit_20260714.md）で指摘したバグの再現テスト。
# 各exampleは「修正後のあるべき挙動」を検証しており、修正されるまでは pending 扱い。
# S1-2で修正したら該当の pending 行を削除して回帰テストに昇格させること。
RSpec.describe "監査指摘バグの回帰テスト", type: :request do
  let(:admin_user) { create(:admin_user) }

  describe "C-3: serviceセクションとパーシャル名の不一致" do
    it "serviceセクションのコンテンツを有効化してもトップページが表示できる" do
      section = create(:section, name: "service", display_name: "Service", is_visible: true)
      create(:section_content, section: section, is_active: true)

      get root_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "C-4: タグフォームが存在しないカラムを参照" do
    before { sign_in admin_user, scope: :admin_user }

    it "タグ新規作成画面が表示できる" do
      get new_admin_tag_path

      expect(response).to have_http_status(:ok)
    end

    it "タグ編集画面が表示できる" do
      tag = create(:tag)
      get edit_admin_tag_path(tag)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "C-5: Contactの担当者アサイン（FK名不一致）" do
    it "assigned_to_idを設定するとadmin_user関連が取得できる" do
      contact = create(:contact)
      contact.update!(assigned_to_id: admin_user.id)

      expect(contact.reload.admin_user).to eq(admin_user)
    end
  end

  describe "C-11: デフォルトOGP画像" do
    it "og-default.jpg が有効なJPEG画像である" do
      path = Rails.public_path.join("og-default.jpg")

      expect(File.exist?(path)).to be true
      # JPEGマジックバイト（FF D8 FF）で実画像であることを検証
      expect(File.binread(path, 3).bytes).to eq([0xFF, 0xD8, 0xFF])
    end
  end

  describe "M-17: contacts editテンプレート不在" do
    it "テンプレート不在だったeditルートは廃止されている" do
      expect(Rails.application.routes.url_helpers).not_to respond_to(:edit_admin_contact_path)
    end

    it "管理画面から担当者をアサインできる（C-5修正の経路検証）" do
      sign_in admin_user, scope: :admin_user
      contact = create(:contact)

      patch admin_contact_path(contact), params: { contact: { assigned_to_id: admin_user.id, notes: "対応中" } }

      expect(response).to redirect_to(admin_contact_path(contact))
      expect(contact.reload.admin_user).to eq(admin_user)
    end
  end
end
