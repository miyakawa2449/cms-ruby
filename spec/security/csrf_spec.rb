require "rails_helper"

RSpec.describe "CSRF Protection", type: :request do
  let(:contact_params) do
    {
      contact: {
        name: "Test",
        email: "test@example.com",
        subject: "Test",
        message: "Test message"
      }
    }
  end

  around do |example|
    original_base = ActionController::Base.allow_forgery_protection
    original_config = Rails.application.config.action_controller.allow_forgery_protection
    original_contacts = ContactsController.allow_forgery_protection

    Rails.application.config.action_controller.allow_forgery_protection = true
    ActionController::Base.allow_forgery_protection = true
    ContactsController.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original_base
    Rails.application.config.action_controller.allow_forgery_protection = original_config
    ContactsController.allow_forgery_protection = original_contacts
  end

  it "accepts JSON requests without CSRF token" do
    post contacts_path, params: contact_params, as: :json
    expect(response).to have_http_status(:created)
  end

  it "accepts JSON requests even with invalid CSRF token" do
    post contacts_path, params: contact_params, as: :json, headers: { "X-CSRF-Token" => "invalid" }
    expect(response).to have_http_status(:created)
  end

  it "allows GET requests without token" do
    expect { get root_path }.not_to raise_error
  end

  it "renders CSRF meta tags" do
    get root_path
    expect(response.body).to include("csrf-token")
  end
end
