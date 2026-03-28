# frozen_string_literal: true

class PriceAlertCheckerJob < ApplicationJob
  DEFAULT_TIMEZONE = 'Australia/Melbourne'
  ALERT_HOUR_START = 8
  ALERT_HOUR_END   = 21

  def perform
    check_price_alerts
    check_expiring_saved_deals
  end

  private

  def check_price_alerts
    PriceAlert.active.includes(:product).find_each do |alert|
      next unless alert.product.price.to_f <= alert.target_price.to_f
      next unless within_allowed_hours?(alert)

      DealsMailer.price_alert(alert).deliver_later
      alert.trigger!
    end
  end

  def check_expiring_saved_deals
    expiry_cutoff = 24.hours.from_now

    # Find products expiring within 24h
    expiring_products = Product.where(expired: false)
                               .where('flash_expires_at IS NOT NULL AND flash_expires_at <= ? AND flash_expires_at > ?',
                                      expiry_cutoff, Time.current)

    return if expiring_products.empty?

    expiring_ids = expiring_products.index_by(&:id)

    # Find saved deals for these products with email info
    SavedDeal.where(product_id: expiring_ids.keys)
             .includes(:product)
             .find_each do |saved|
      product = expiring_ids[saved.product_id]
      next unless product

      email = resolve_email_for_saved(saved)
      next if email.blank?

      PriceAlertMailer.deal_expiring_soon(email, product).deliver_later
    rescue => e
      Rails.logger.warn "PriceAlertCheckerJob - expiry check error for saved_deal #{saved.id}: #{e.message}"
    end
  end

  def resolve_email_for_saved(saved)
    if saved.user_id.present?
      User.find_by(id: saved.user_id)&.email
    elsif saved.session_id.present?
      Subscriber.find_by(session_id: saved.session_id)&.email ||
        PriceAlert.where(triggered: false).find_by("session_id = ? OR email IS NOT NULL", saved.session_id)&.email
    end
  end

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
