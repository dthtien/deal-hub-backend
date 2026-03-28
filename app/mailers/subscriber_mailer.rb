# frozen_string_literal: true

class SubscriberMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'deals@ozvfy.com')

  def personalised_deals(subscriber, deals)
    @subscriber = subscriber
    @deals = deals
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @unsubscribe_url = "#{@site_url}/unsubscribe?token=#{subscriber.unsubscribe_token}"
    @preferences_url = "#{@site_url}/subscribe/preferences?token=#{subscriber.unsubscribe_token}"

    prefs = subscriber.preferences || {}
    @categories = Array(prefs['categories'])
    @stores = Array(prefs['stores'])

    subject_text = "Your Personalised Deals from OzVFY - Today's Top Picks"

    log = NotificationLog.create!(
      notification_type: 'personalised_digest',
      recipient: subscriber.email,
      subject: subject_text,
      status: 'sent'
    )
    @tracking_pixel_url = tracking_pixel_url(subscriber.id, log.id)

    mail(to: subscriber.email, subject: subject_text)
  end
end
