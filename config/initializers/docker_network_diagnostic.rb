# Docker Network Diagnostic for Rails 8.0.4
# Diagnoses container-to-container connectivity issues

if Rails.env.development?
  Rails.application.configure do
    config.after_initialize do
      begin
        # Test container network connectivity
        require "socket"

        # Test if 'db' hostname resolves
        db_ip = Socket.getaddrinfo("db", nil).first[2]
        Rails.logger.info "🌐 DB container IP resolved: #{db_ip}"

        # Test TCP connectivity to PostgreSQL port
        socket = TCPSocket.new("db", 5432)
        socket.close
        Rails.logger.info "✅ TCP connection to db:5432 successful"

      rescue => e
        Rails.logger.error "❌ Docker network issue: #{e.message}"
        Rails.logger.error "💡 Suggestion: Check docker-compose network configuration"
      end
    end
  end
end
