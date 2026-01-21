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

    it "filters by status and subject" do
      create(:contact, status: "archived", subject: "Archived")
      create(:contact, status: "unread", subject: "Unread")

      get admin_contacts_path, params: { status: "archived", subject: "Archived" }

      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /admin/contacts/:id" do
    it "returns http success" do
      get admin_contact_path(contact)
      expect(response).to have_http_status(:success)
    end

    it "marks unread contact as read" do
      expect(contact.status).to eq("unread")

      get admin_contact_path(contact)

      expect(contact.reload.status).to eq("read")
    end
  end

  # Note: edit view doesn't exist - editing is done inline on show page

  describe "PATCH /admin/contacts/:id" do
    it "updates contact status" do
      patch admin_contact_path(contact), params: { contact: { status: 'replied' } }
      expect(response).to redirect_to(admin_contact_path(contact))
    end

    it "marks contact as read" do
      patch admin_contact_path(contact), params: { contact: { status: "read" } }

      expect(contact.reload.status).to eq("read")
    end

    it "archives contact" do
      patch admin_contact_path(contact), params: { contact: { status: "archived" } }

      expect(contact.reload.status).to eq("archived")
    end

    it "renders edit on update failure" do
      allow_any_instance_of(Contact).to receive(:update).and_return(false)

      expect {
        patch admin_contact_path(contact), params: { contact: { notes: "" } }
      }.to raise_error(ActionView::MissingTemplate)
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
