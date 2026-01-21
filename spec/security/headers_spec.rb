require "rails_helper"

RSpec.describe "Security Headers", type: :request do
  let(:paths) { [root_path, blog_path, new_admin_user_session_path] }

  it "sets Content Security Policy header" do
    get root_path
    expect(response.headers["Content-Security-Policy"]).to be_present
  end

  it "includes CSP directives" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("default-src")
    expect(csp).to include("script-src")
    expect(csp).to include("style-src")
    expect(csp).to include("object-src 'none'")
  end

  it "includes frame-ancestors directive" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("frame-ancestors 'none'")
  end

  it "includes base-uri directive" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("base-uri 'self'")
  end

  it "includes form-action directive" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("form-action 'self'")
  end

  it "includes img-src directive" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("img-src")
  end

  it "includes connect-src directive" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("connect-src")
  end

  it "includes frame-src directive" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("frame-src")
  end

  it "includes worker-src directive" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("worker-src")
  end

  it "includes media-src directive" do
    get root_path
    csp = response.headers["Content-Security-Policy"]
    expect(csp).to include("media-src")
  end

  it "sets X-Frame-Options" do
    get root_path
    expect(response.headers["X-Frame-Options"]).to eq("SAMEORIGIN")
  end

  it "sets headers on admin login page" do
    get new_admin_user_session_path
    expect(response.headers["X-Frame-Options"]).to eq("SAMEORIGIN")
    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
  end

  it "sets X-Content-Type-Options" do
    get root_path
    expect(response.headers["X-Content-Type-Options"]).to eq("nosniff")
  end

  it "sets Referrer-Policy" do
    get root_path
    expect(response.headers["Referrer-Policy"]).to eq("strict-origin-when-cross-origin")
  end

  it "sets Permissions-Policy" do
    get root_path
    expect(response.headers["Permissions-Policy"]).to include("geolocation=()")
  end

  it "disables microphone and camera in Permissions-Policy" do
    get root_path
    policy = response.headers["Permissions-Policy"]
    expect(policy).to include("microphone=()")
    expect(policy).to include("camera=()")
  end

  it "sets X-XSS-Protection" do
    get root_path
    expect(response.headers["X-XSS-Protection"]).to eq("1; mode=block")
  end

  it "does not set HSTS in test environment" do
    get root_path
    expect(response.headers["Strict-Transport-Security"]).to be_nil
  end

  it "includes required headers on key pages" do
    paths.each do |path|
      get path
      expect(response.headers["X-Frame-Options"]).to be_present
      expect(response.headers["X-Content-Type-Options"]).to be_present
      expect(response.headers["Referrer-Policy"]).to be_present
      expect(response.headers["Content-Security-Policy"]).to be_present
    end
  end
end
