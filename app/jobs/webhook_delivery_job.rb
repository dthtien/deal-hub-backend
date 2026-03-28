# frozen_string_literal: true

class WebhookDeliveryJob < ApplicationJob
  queue_as :webhooks

  def perform(webhook_id, event, payload)
    webhook = Webhook.find_by(id: webhook_id)
    return unless webhook&.active?

    body = payload.to_json
    sig  = OpenSSL::HMAC.hexdigest('SHA256', webhook.secret, body)

    response_status = nil
    failed = false

    begin
      response = Net::HTTP.start(uri(webhook.url).host, uri(webhook.url).port,
                                 use_ssl: uri(webhook.url).scheme == 'https',
                                 open_timeout: 5, read_timeout: 10) do |http|
        req = Net::HTTP::Post.new(uri(webhook.url).request_uri)
        req['Content-Type']      = 'application/json'
        req['X-OzVFY-Event']     = event
        req['X-OzVFY-Signature'] = "sha256=#{sig}"
        req.body = body
        http.request(req)
      end
      response_status = response.code.to_i
    rescue StandardError => e
      Rails.logger.warn "[WebhookDelivery] #{webhook_id} failed: #{e.message}"
      failed = true
    end

    WebhookDelivery.create!(
      webhook_id:      webhook_id,
      payload:         payload,
      response_status: response_status,
      delivered_at:    failed ? nil : Time.current,
      failed:          failed
    )
  end

  private

  def uri(url)
    @uri ||= URI.parse(url)
  end
end
