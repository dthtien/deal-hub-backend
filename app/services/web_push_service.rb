class WebPushService
  VAPID_PUBLIC_KEY  = ENV['VAPID_PUBLIC_KEY']
  VAPID_PRIVATE_KEY = ENV['VAPID_PRIVATE_KEY']

  def self.send_deal_notification(product)
    payload = {
      title: "#{product.discount.to_i}% OFF — #{product.name.truncate(50)}",
      body:  "$#{product.price} (was $#{product.old_price}) at #{product.store}",
      url:   "https://www.ozvfy.com/deals/#{product.id}"
    }.to_json

    PushSubscription.find_each do |sub|
      Webpush.payload_send(
        message: payload,
        endpoint: sub.endpoint,
        p256dh: sub.p256dh,
        auth: sub.auth,
        vapid: {
          subject: 'mailto:deals@ozvfy.com',
          public_key:  VAPID_PUBLIC_KEY,
          private_key: VAPID_PRIVATE_KEY
        }
      )
    rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription
      sub.destroy
    rescue => e
      Rails.logger.error("WebPush error: #{e.message}")
    end
  end
end
