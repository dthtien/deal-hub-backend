# frozen_string_literal: true

class PersonalisedDigestMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'deals@ozvfy.com')

  def digest(subscriber, deals)
    @subscriber = subscriber
    @deals = deals
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @unsubscribe_url = "#{@site_url}/unsubscribe?token=#{subscriber.unsubscribe_token}"
    @preferences_url = "#{@site_url}/subscribe/preferences?token=#{subscriber.unsubscribe_token}"

    prefs = subscriber.preferences || {}
    @categories = Array(prefs['categories'])
    @max_price = prefs['max_price']

    mail(
      to: subscriber.email,
      subject: "🎯 Your Personalised Deals from OzVFY"
    )
  end
end
