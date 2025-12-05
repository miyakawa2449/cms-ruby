require 'rails_helper'

RSpec.describe "Admin::Contacts", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/admin/contacts/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/admin/contacts/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/admin/contacts/edit"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/admin/contacts/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/admin/contacts/destroy"
      expect(response).to have_http_status(:success)
    end
  end

end
