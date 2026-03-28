class WebPushService
  VAPID_PUBLIC_KEY  = ENV['VAPID_PUBLIC_KEY']
  VAPID_PRIVATE_KEY = ENV['VAPID_PRIVATE_KEY']

  def self.send_store_notification(store_name, best_deal, deal_count)
    count_label = deal_count == 1 ? '1 new deal' : "#{deal_count} new deals"
    payload = {
      title: "New deals from #{store_name}",
      body:  "#{count_label} available - best: #{best_deal.name.truncate(40)}",
      url:   "https://www.ozvfy.com/stores/#{URI.encode_www_form_component(store_name)}"
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
      Rails.logger.error("WebPush store notification error: #{e.message}")
    end
  end

  def self.send_deal_notification(product)
    payload = {
      title: "#{product.discount.to_i}% OFF -- #{product.name.truncate(50)}",
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

  # Personalised push notification with deal-specific content
  def self.send_personalised(subscription, title:, body:, icon: nil, url: nil, badge: '/badge-icon.png')
    payload = {
      title: title,
      body:  body,
      icon:  icon || '/logo.png',
      badge: badge,
      url:   url || 'https://www.ozvfy.com'
    }.to_json

    begin
      Webpush.payload_send(
        message: payload,
        endpoint: subscription.endpoint,
        p256dh: subscription.p256dh,
        auth: subscription.auth,
        vapid: {
          subject: 'mailto:deals@ozvfy.com',
          public_key:  VAPID_PUBLIC_KEY,
          private_key: VAPID_PRIVATE_KEY
        }
      )
    rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription
      subscription.destroy
    rescue => e
      Rails.logger.error("WebPush personalised error: #{e.message}")
    end
  end

  # Send personalised notification about a specific deal to all subscribers
  def self.broadcast_deal(product)
    icon = product.image_url.presence || '/logo.png'
    url  = "https://www.ozvfy.com/deals/#{product.id}"
    title = "#{product.discount.to_i}% OFF -- #{product.name.truncate(50)}"
    body  = "$#{product.price} (was $#{product.old_price}) at #{product.store}"

    PushSubscription.find_each do |sub|
      send_personalised(sub, title: title, body: body, icon: icon, url: url)
    end
  end
end
