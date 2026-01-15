require 'rails_helper'

RSpec.describe "Admin::Contacts", type: :request do
  let(:admin_user) { create(:admin_user) }
  let(:contact) { create(:contact) }

  before do
    sign_in admin_user, scope: :admin_user
  end

  describe "GET /admin/contacts" do
    it "returns http success" do
      get admin_contacts_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/contacts/:id" do
    it "returns http success" do
      get admin_contact_path(contact)
      expect(response).to have_http_status(:success)
    end
  end

  # Note: edit view doesn't exist - editing is done inline on show page

  describe "PATCH /admin/contacts/:id" do
    it "updates contact status" do
      patch admin_contact_path(contact), params: { contact: { status: 'replied' } }
      expect(response).to redirect_to(admin_contact_path(contact))
    end
  end

  describe "DELETE /admin/contacts/:id" do
    it "deletes the contact" do
      contact # create contact
      expect {
        delete admin_contact_path(contact)
      }.to change(Contact, :count).by(-1)
    end
  end
end
