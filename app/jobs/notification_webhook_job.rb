# frozen_string_literal: true

# Sends Slack/Discord webhook notifications for new deals with discount > 40%
class NotificationWebhookJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.find_by(id: product_id)
    return unless product
    return unless product.discount.to_f > 40

    slack_url   = ENV['SLACK_WEBHOOK_URL']
    discord_url = ENV['DISCORD_WEBHOOK_URL']

    name     = product.name
    discount = product.discount.to_f.round
    price    = product.price.to_f

    if slack_url.present?
      payload = { text: "New deal: #{name} - #{discount}% off - $#{price}" }
      post_webhook(slack_url, payload)
    end

    if discord_url.present?
      payload = {
        content: "New deal: #{name} - #{discount}% off - $#{price}",
        embeds: [
          {
            title: name,
            description: "#{discount}% off - now $#{price}",
            color: 0xff6600
          }
        ]
      }
      post_webhook(discord_url, payload)
    end
  end

  private

  def post_webhook(url, payload)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request.body = payload.to_json
    http.request(request)
  rescue => e
    Rails.logger.error "NotificationWebhookJob - failed to post to #{url}: #{e.message}"
  end
end
