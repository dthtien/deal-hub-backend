class ApplicationMailer < ActionMailer::Base
  default from: "from@example.com"
  layout "mailer"

  private

  def tracking_pixel_url(subscriber_id, notification_log_id)
    token = Base64.strict_encode64("#{subscriber_id}:#{notification_log_id}")
    site_url = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')
    "#{site_url}/track/open/#{token}"
  end
end
