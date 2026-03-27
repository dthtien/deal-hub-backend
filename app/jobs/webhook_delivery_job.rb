# frozen_string_literal: true

class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  def perform(webhook_id, event, payload)
    webhook = Webhook.find_by(id: webhook_id)
    return unless webhook&.active?

    body    = payload.to_json
    sig     = OpenSSL::HMAC.hexdigest('SHA256', webhook.secret, body)

    Net::HTTP.start(uri(webhook.url).host, uri(webhook.url).port,
                    use_ssl: uri(webhook.url).scheme == 'https',
                    open_timeout: 5, read_timeout: 10) do |http|
      req = Net::HTTP::Post.new(uri(webhook.url).request_uri)
      req['Content-Type'] = 'application/json'
      req['X-OzVFY-Event']     = event
      req['X-OzVFY-Signature'] = "sha256=#{sig}"
      req.body = body
      http.request(req)
    end
  rescue StandardError => e
    Rails.logger.warn "[WebhookDelivery] #{webhook_id} failed: #{e.message}"
  end

  private

  def uri(url)
    @uri ||= URI.parse(url)
  end
end
