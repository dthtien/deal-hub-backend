# frozen_string_literal: true

class PriceAlertMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'deals@ozvfy.com')

  def already_met(alert, product)
    @alert = alert
    @product = product
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @deal_url = "#{@site_url}/deals/#{@product.id}"

    mail(
      to: @alert.email,
      subject: "Your target price is already met for #{@product.name.truncate(50)}"
    )
  end

  def daily_digest(email, alerts)
    @email = email
    @alerts = alerts
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @triggered_at = Time.current

    subject_line = "Your daily price alert digest - #{alerts.size} deal#{alerts.size == 1 ? '' : 's'} matched!"

    message = mail(to: email, subject: subject_line)

    begin
      NotificationLog.create!(
        notification_type: 'price_alert_digest',
        recipient:         email,
        subject:           subject_line,
        status:            'sent'
      )
    rescue StandardError => e
      Rails.logger.error("[PriceAlertMailer] Failed to log notification: #{e.message}")
    end

    message
  end
end
