# frozen_string_literal: true

module Security
  # Service for monitoring error rates and traffic anomalies
  class MonitorService
    THRESHOLDS = {
      error_rate: 0.05, # 5%
      errors_per_minute: 10,
      requests_per_minute: 1000,
      requests_per_ip: 100
    }.freeze

    def check_error_rate
      total_requests = count_requests(10.minutes.ago)
      error_requests = count_errors(10.minutes.ago)

      return if total_requests.zero?

      error_rate = error_requests.to_f / total_requests

      if error_rate > THRESHOLDS[:error_rate]
        alert_high_error_rate(error_rate, total_requests, error_requests)
      end
    end

    def check_traffic_anomaly
      current_rpm = count_requests(1.minute.ago)

      if current_rpm > THRESHOLDS[:requests_per_minute]
        alert_traffic_spike(current_rpm)
      end
    end

    private

    def count_requests(since)
      sum_metric("requests", since)
    end

    def count_errors(since)
      sum_metric("errors", since)
    end

    def sum_metric(metric, since)
      return 0 unless since

      buckets = minute_buckets(since, Time.current)
      buckets.sum do |bucket|
        Rails.cache.read(cache_key(metric, bucket)).to_i
      end
    end

    def minute_buckets(start_time, end_time)
      start_bucket = start_time.change(sec: 0)
      end_bucket = end_time.change(sec: 0)
      buckets = []

      current = start_bucket
      while current <= end_bucket
        buckets << current
        current += 1.minute
      end

      buckets
    end

    def cache_key(metric, bucket_time)
      "security_monitor:#{metric}:#{bucket_time.strftime('%Y%m%d%H%M')}"
    end

    def alert_high_error_rate(rate, total, errors)
      SecurityMailer.high_error_rate_alert(
        rate: rate,
        total_requests: total,
        error_requests: errors
      ).deliver_now

      if SlackNotifier.enabled?
        SlackNotifier.notify_health_check_alert(
          "error_rate",
          "warning",
          { rate: "#{(rate * 100).round(2)}%", total: total, errors: errors }
        )
      end
    rescue StandardError => e
      Rails.logger.error "Failed to send high error rate alert: #{e.message}"
    end

    def alert_traffic_spike(rpm)
      SecurityMailer.traffic_spike_alert(
        requests_per_minute: rpm
      ).deliver_now

      if SlackNotifier.enabled?
        SlackNotifier.notify_health_check_alert(
          "traffic",
          "warning",
          { requests_per_minute: rpm, threshold: THRESHOLDS[:requests_per_minute] }
        )
      end
    rescue StandardError => e
      Rails.logger.error "Failed to send traffic spike alert: #{e.message}"
    end
  end
end
