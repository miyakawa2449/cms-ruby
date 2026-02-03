# frozen_string_literal: true

# Track request/error counts for Security::MonitorService
ActiveSupport::Notifications.subscribe("process_action.action_controller") do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  payload = event.payload

  path = payload[:path].to_s
  next if path.start_with?("/assets")

  bucket = Time.current.change(sec: 0)
  bucket_key = bucket.strftime("%Y%m%d%H%M")
  expires_in = 2.hours

  Rails.cache.increment("security_monitor:requests:#{bucket_key}", 1, expires_in: expires_in)

  status = payload[:status].to_i
  if status >= 500
    Rails.cache.increment("security_monitor:errors:#{bucket_key}", 1, expires_in: expires_in)
  end
end
