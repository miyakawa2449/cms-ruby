# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

puts "🌱 Starting database seeding..."

# Create AdminUser for development/test
admin = AdminUser.find_or_create_by!(email: "admin@portfolio.dev") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

puts "✅ AdminUser created: #{admin.email}"
puts "🎯 Password: password123"
puts "🚀 Seeding completed successfully!"
