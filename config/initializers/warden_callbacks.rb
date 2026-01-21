# frozen_string_literal: true

# Warden callbacks for security logging
Warden::Manager.after_set_user except: :fetch do |user, auth, opts|
  next unless opts[:scope] == :admin_user && opts[:event] == :authentication

  SecurityLogger.log_login_success(user, auth.request)
end

Warden::Manager.before_failure do |env, opts|
  next unless opts[:scope] == :admin_user

  request = Rack::Request.new(env)
  params = request.params
  email = params.dig("admin_user", "email") || env.dig("warden.options", :email)
  SecurityLogger.log_login_failure(email, request)
end

Warden::Manager.before_logout do |user, auth, opts|
  next unless opts[:scope] == :admin_user

  SecurityLogger.log_logout(user, auth.request)
end
