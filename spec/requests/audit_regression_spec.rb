require "rails_helper"

# 監査レポート（docs/analysis/generic_cms_audit_20260714.md）で指摘したバグの再現テスト。
# 各exampleは「修正後のあるべき挙動」を検証しており、修正されるまでは pending 扱い。
# S1-2で修正したら該当の pending 行を削除して回帰テストに昇格させること。
RSpec.describe "監査指摘バグの回帰テスト", type: :request do
  let(:admin_user) { create(:admin_user) }

  describe "C-3: serviceセクションとパーシャル名の不一致" do
    it "serviceセクションのコンテンツを有効化してもトップページが表示できる" do
      pending "監査C-3: _service.html.erb が存在せず MissingTemplate になる"

      section = create(:section, name: "service", display_name: "Service", is_visible: true)
      create(:section_content, section: section, is_active: true)

      get root_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "C-4: タグフォームが存在しないカラムを参照" do
    before { sign_in admin_user, scope: :admin_user }

    it "タグ新規作成画面が表示できる" do
      pending "監査C-4: _form.html.erb が description/color/icon を参照し NoMethodError になる"

      get new_admin_tag_path

      expect(response).to have_http_status(:ok)
    end

    it "タグ編集画面が表示できる" do
      pending "監査C-4: _form.html.erb が description/color/icon を参照し NoMethodError になる"

      tag = create(:tag)
      get edit_admin_tag_path(tag)

      expect(response).to have_http_status(:ok)
    end
  end

  describe "C-5: Contactの担当者アサイン（FK名不一致）" do
    it "assigned_to_idを設定するとadmin_user関連が取得できる" do
      pending "監査C-5: belongs_toのforeign_keyが実在しないカラム assigned_to を指しており関連が常にnil"

      contact = create(:contact)
      contact.update!(assigned_to_id: admin_user.id)

      expect(contact.reload.admin_user).to eq(admin_user)
    end
  end

  describe "M-17: contacts editテンプレート不在" do
    before { sign_in admin_user, scope: :admin_user }

    it "問い合わせ編集画面が表示できる（またはeditアクションが存在しない）" do
      pending "監査M-17: editアクションはあるが edit.html.erb が存在せず MissingTemplate になる"

      contact = create(:contact)
      get edit_admin_contact_path(contact)

      expect(response).to have_http_status(:ok)
    end
  end
end
