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
end
