# frozen_string_literal: true

class ReEngagementMailer < ApplicationMailer
  default from: ENV.fetch('MAILER_FROM', 'deals@ozvfy.com')

  def we_miss_you(subscriber, deals)
    @subscriber = subscriber
    @deals = deals
    @site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    @unsubscribe_url = "#{@site_url}/unsubscribe?token=#{subscriber.unsubscribe_token}"

    mail(
      to: subscriber.email,
      subject: "We miss you! Here are today's best deals on OzVFY"
    )
  end
end
