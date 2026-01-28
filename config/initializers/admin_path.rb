require Rails.root.join("app/services/admin_path/resolver").to_s

begin
  ENV["ADMIN_PATH"] = AdminPath::Resolver.current_path
rescue StandardError => e
  Rails.logger.warn("AdminPath initializer skipped: #{e.class} #{e.message}")
end
