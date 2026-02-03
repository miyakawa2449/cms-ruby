# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::Internal::Security", type: :request do
  let(:valid_token) { "test_internal_api_token" }

  before do
    host! "localhost"
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("INTERNAL_API_TOKEN").and_return(valid_token)
  end

  describe "POST /api/internal/security/brakeman" do
    let(:path) { "/api/internal/security/brakeman" }
    let(:valid_results) do
      {
        warnings: [
          {
            warning_type: "SQL Injection",
            confidence: "High",
            message: "Possible SQL injection",
            file: "app/models/user.rb",
            line: 42
          }
        ]
      }
    end

    context "with valid token" do
      let(:headers) do
        {
          "Authorization" => "Bearer #{valid_token}",
          "Content-Type" => "application/json"
        }
      end

      it "creates a security scan" do
        expect {
          post path, params: valid_results.to_json, headers: headers
        }.to change(SecurityScan, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)["success"]).to be true
      end

      it "returns scan info" do
        post path, params: valid_results.to_json, headers: headers

        json = JSON.parse(response.body)
        expect(json["scan_id"]).to be_present
        expect(json["vulnerabilities_count"]).to eq(1)
      end
    end

    context "with invalid token" do
      let(:headers) do
        {
          "Authorization" => "Bearer invalid_token",
          "Content-Type" => "application/json"
        }
      end

      it "returns unauthorized" do
        post path, params: valid_results.to_json, headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "without token" do
      let(:headers) { { "Content-Type" => "application/json" } }

      it "returns unauthorized" do
        post path, params: valid_results.to_json, headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/internal/security/bundler_audit" do
    let(:path) { "/api/internal/security/bundler_audit" }
    let(:valid_results) do
      {
        results: [
          {
            gem: { name: "rails", version: "7.0.0" },
            advisories: [
              {
                title: "XSS vulnerability",
                cve: "CVE-2024-12345",
                criticality: "High",
                description: "A XSS vulnerability",
                patched_versions: [ ">= 7.0.1" ]
              }
            ]
          }
        ]
      }
    end

    context "with valid token" do
      let(:headers) do
        {
          "Authorization" => "Bearer #{valid_token}",
          "Content-Type" => "application/json"
        }
      end

      it "creates a security scan" do
        expect {
          post path, params: valid_results.to_json, headers: headers
        }.to change(SecurityScan, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end
  end
end
