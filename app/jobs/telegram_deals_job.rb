# frozen_string_literal: true

class TelegramDealsJob < ApplicationJob
  sidekiq_options retry: 2

  def perform
    return unless ENV['TELEGRAM_BOT_TOKEN'].present? && ENV['TELEGRAM_CHAT_ID'].present?

    deals = Product
      .where(expired: false)
      .where('discount > 0')
      .order(discount: :desc)
      .limit(20)

    top_deals = deals.sort_by { |d| -(d.deal_score || 0) }.first(5)

    return if top_deals.empty?

    message = build_message(top_deals)

    TelegramService.send_message(
      chat_id: ENV['TELEGRAM_CHAT_ID'],
      text: message,
      disable_web_page_preview: true
    )

    Rails.logger.info "TelegramDealsJob: posted #{top_deals.size} deals to Telegram"
  end

  private

  def build_message(deals)
    header = "🛍️ <b>OzVFY Top Deals Today</b>\nBest deals from across Australia:\n\n"
    footer = "\n\n📱 <a href='https://www.ozvfy.com'>Browse all deals →</a>"
    divider = "\n——————\n"

    deal_lines = deals.map { |deal| format_deal(deal) }

    header + deal_lines.join(divider) + footer
  end

  def format_deal(deal)
    price = format_price(deal.price)
    old_price = deal.old_price.present? ? " <s>#{format_price(deal.old_price)}</s>" : ""
    discount_text = deal.discount.to_i > 0 ? " (-#{deal.discount.to_i}% off)" : ""
    store_name = deal.store.to_s.titleize

    "🔥 <b>#{ERB::Util.html_escape(deal.name)}</b>\n" \
    "💰 <b>#{price}</b>#{old_price}#{discount_text}\n" \
    "🏪 #{store_name}\n" \
    "🔗 <a href=\"https://www.ozvfy.com/deals/#{deal.id}\">View Deal →</a>"
  end

  def format_price(amount)
    "$#{'%.2f' % amount}"
  end
end
