# frozen_string_literal: true

class PriceAlertCheckerJob < ApplicationJob
  DEFAULT_TIMEZONE = 'Australia/Melbourne'
  ALERT_HOUR_START = 8
  ALERT_HOUR_END   = 21

  def perform
    PriceAlert.active.includes(:product).find_each do |alert|
      next unless alert.product.price.to_f <= alert.target_price.to_f
      next unless within_allowed_hours?(alert)

      DealsMailer.price_alert(alert).deliver_later
      alert.trigger!
    end
  end

  private

  def within_allowed_hours?(alert)
    tz_name = resolve_timezone(alert)
    begin
      tz = ActiveSupport::TimeZone[tz_name] || ActiveSupport::TimeZone[DEFAULT_TIMEZONE]
      local_hour = Time.current.in_time_zone(tz).hour
      local_hour >= ALERT_HOUR_START && local_hour < ALERT_HOUR_END
    rescue => e
      Rails.logger.warn "PriceAlertCheckerJob - timezone error for alert #{alert.id}: #{e.message}"
      true
    end
  end

  def resolve_timezone(alert)
    subscriber = Subscriber.find_by(email: alert.email)
    return DEFAULT_TIMEZONE unless subscriber

    prefs = subscriber.preferences || {}
    tz = prefs['timezone'].to_s.strip
    tz.present? ? tz : DEFAULT_TIMEZONE
  end
end
