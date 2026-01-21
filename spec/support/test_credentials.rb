# frozen_string_literal: true

module TestCredentials
  def self.admin_email
    ENV.fetch("TEST_ADMIN_EMAIL", "admin@example.test")
  end

  def self.admin_password
    ENV.fetch("TEST_ADMIN_PASSWORD", "test_password_123!")
  end
end
