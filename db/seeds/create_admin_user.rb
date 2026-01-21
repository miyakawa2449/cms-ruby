admin_email = ENV.fetch("ADMIN_EMAIL", "admin@example.test")
admin_password = ENV.fetch("ADMIN_PASSWORD", "")

if admin_password.empty?
  if Rails.env.production?
    raise "ADMIN_PASSWORD is not set. Refusing to create an admin user in production."
  else
    admin_password = SecureRandom.base58(12)
    puts "Generated ADMIN_PASSWORD for seeding: #{admin_password}"
  end
end

AdminUser.create!(
  email: admin_email,
  password: admin_password,
  password_confirmation: admin_password
)

puts "Admin user created successfully: #{admin_email}"
