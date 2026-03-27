# frozen_string_literal: true

class PriceAlertMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'deals@ozvfy.com')

  def daily_digest(email, alerts)
    @email = email
    @alerts = alerts
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @triggered_at = Time.current

    mail(
      to: email,
      subject: "🔔 Your daily price alert digest — #{alerts.size} deal#{alerts.size == 1 ? '' : 's'} matched!"
    )
  end
end
