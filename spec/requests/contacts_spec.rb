require 'rails_helper'

RSpec.describe "Contacts", type: :request do
  describe "POST /contacts" do
    let(:valid_params) do
      {
        contact: {
          name: "Test User",
          email: "test@example.com",
          subject: "お問い合わせ",
          message: "お問い合わせ内容です。",
          website: "" # honeypot field
        }
      }
    end

    it "creates a new contact" do
      expect {
        post contacts_path, params: valid_params, as: :json
      }.to change(Contact, :count).by(1)
    end

    it "returns created status" do
      post contacts_path, params: valid_params, as: :json
      expect(response).to have_http_status(:created)
    end

    it "returns success message" do
      post contacts_path, params: valid_params, as: :json
      json = JSON.parse(response.body)
      expect(json['status']).to eq('success')
    end
  end
end
