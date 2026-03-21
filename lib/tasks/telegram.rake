# frozen_string_literal: true

namespace :telegram do
  desc "Send daily deals to Telegram"
  task send_deals: :environment do
    TelegramDealsJob.perform_now
  end

  desc "Test Telegram bot connection"
  task test: :environment do
    result = TelegramService.send_message(
      chat_id: ENV['TELEGRAM_CHAT_ID'],
      text: "✅ OzVFY Telegram bot is connected!"
    )
    puts result
  end
end
