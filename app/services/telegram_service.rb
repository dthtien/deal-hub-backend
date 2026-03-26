# frozen_string_literal: true

class TelegramService
  API_URL = "https://api.telegram.org/bot#{ENV['TELEGRAM_BOT_TOKEN']}"

  def self.send_message(chat_id:, text:, parse_mode: 'HTML', disable_web_page_preview: false)
    uri = URI("#{API_URL}/sendMessage")
    body = { chat_id: chat_id, text: text, parse_mode: parse_mode, disable_web_page_preview: disable_web_page_preview }
    response = Net::HTTP.post(uri, body.to_json, 'Content-Type' => 'application/json')
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error("TelegramService error: #{e.message}")
    nil
  end

  # Send a photo with caption — much higher engagement than text-only
  def self.send_photo(chat_id:, photo_url:, caption:, parse_mode: 'HTML')
    uri = URI("#{API_URL}/sendPhoto")
    body = { chat_id: chat_id, photo: photo_url, caption: caption, parse_mode: parse_mode }
    response = Net::HTTP.post(uri, body.to_json, 'Content-Type' => 'application/json')
    result = JSON.parse(response.body)
    # Fall back to text message if photo fails (bad URL, too large, etc.)
    unless result['ok']
      Rails.logger.warn "TelegramService photo failed (#{result['description']}), falling back to text"
      send_message(chat_id: chat_id, text: caption, disable_web_page_preview: false)
    end
    result
  rescue => e
    Rails.logger.error("TelegramService error: #{e.message}")
    nil
  end

  # Send a media group (up to 10 photos with captions) — great for deal roundups
  def self.send_media_group(chat_id:, media:)
    uri = URI("#{API_URL}/sendMediaGroup")
    body = { chat_id: chat_id, media: media.to_json }
    response = Net::HTTP.post(uri, body.to_json, 'Content-Type' => 'application/json')
    JSON.parse(response.body)
  rescue => e
    Rails.logger.error("TelegramService error: #{e.message}")
    nil
  end
end
