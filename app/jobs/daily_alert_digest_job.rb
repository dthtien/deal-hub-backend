# frozen_string_literal: true

class DailyAlertDigestJob < ApplicationJob
  queue_as :default

  def perform
    # Find all triggered alerts in the past 24 hours
    recent_alerts = PriceAlert
      .includes(:product)
      .where(triggered: true)
      .where('triggered_at >= ?', 24.hours.ago)
      .where.not(email: nil)

    # Group by email and send one digest per subscriber
    alerts_by_email = recent_alerts.group_by(&:email)

    alerts_by_email.each do |email, alerts|
      next if email.blank?
      PriceAlertMailer.daily_digest(email, alerts).deliver_later
    rescue => e
      Rails.logger.error "DailyAlertDigestJob — failed to send digest to #{email}: #{e.message}"
    end

    Rails.logger.info "DailyAlertDigestJob — sent digests to #{alerts_by_email.size} subscribers"
  end
end
