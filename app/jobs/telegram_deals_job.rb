# frozen_string_literal: true

class TelegramDealsJob < ApplicationJob
  sidekiq_options retry: 2

  CHANNEL = '@ozvfys'
  SITE_URL = 'https://www.ozvfy.com'

  def perform
    return unless ENV['TELEGRAM_BOT_TOKEN'].present?

    deals = Product
      .where(expired: false)
      .where('discount > 0')
      .where.not(image_url: [nil, ''])
      .order(discount: :desc)
      .limit(50)

    top_deals = deals.sort_by { |d| -(d.deal_score || 0) }.first(5)
    return if top_deals.empty?

    hero = top_deals.first
    rest = top_deals[1..]

    # Send hero deal as photo post
    TelegramService.send_photo(
      chat_id: CHANNEL,
      photo_url: hero.image_url,
      caption: hero_caption(hero)
    )

    # Short delay then send rest as a compact text roundup
    sleep 1
    TelegramService.send_message(
      chat_id: CHANNEL,
      text: roundup_message(rest),
      disable_web_page_preview: true
    )

    Rails.logger.info "TelegramDealsJob: posted #{top_deals.size} deals to Telegram"
  end

  private

  def hero_caption(deal)
    discount = deal.discount.to_i > 0 ? " — <b>#{deal.discount.to_i}% OFF</b>" : ''
    old_price = deal.old_price&.positive? ? "\n<s>Was $#{'%.2f' % deal.old_price}</s>" : ''
    ai_badge = deal.ai_recommendation.present? ? "\n🤖 #{deal.ai_recommendation.gsub('_', ' ')}" : ''

    "🔥 <b>#{ERB::Util.html_escape(deal.name.to_s.truncate(80))}</b>\n\n" \
    "💰 <b>$#{'%.2f' % deal.price}</b>#{discount}#{old_price}#{ai_badge}\n" \
    "🏪 #{deal.store}\n\n" \
    "👉 <a href=\"#{SITE_URL}/deals/#{deal.id}\">Grab this deal →</a>\n\n" \
    "📲 More deals: <a href=\"#{SITE_URL}\">ozvfy.com</a>"
  end

  def roundup_message(deals)
    lines = deals.map { |d| format_deal_line(d) }.join("\n\n")
    "🛒 <b>More deals right now:</b>\n\n#{lines}\n\n" \
    "🔎 <a href=\"#{SITE_URL}\">Browse all #{Time.current.strftime('%A')} deals →</a>"
  end

  def format_deal_line(deal)
    price    = "$#{'%.2f' % deal.price}"
    old      = deal.old_price&.positive? ? " <s>$#{'%.2f' % deal.old_price}</s>" : ''
    discount = deal.discount.to_i > 0 ? " (−#{deal.discount.to_i}%)" : ''
    "• <b>#{ERB::Util.html_escape(deal.name.to_s.truncate(60))}</b>\n" \
    "  #{price}#{old}#{discount} · #{deal.store}\n" \
    "  <a href=\"#{SITE_URL}/deals/#{deal.id}\">View →</a>"
  end
end
