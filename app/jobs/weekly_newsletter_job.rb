# frozen_string_literal: true

class WeeklyNewsletterJob < ApplicationJob
  def perform
    deals = Product
      .includes(:ai_deal_analysis)
      .where(expired: false)
      .where('discount > 0')
      .where('updated_at >= ?', 7.days.ago)
      .order(discount: :desc)
      .limit(10)

    return if deals.empty?

    Subscriber.active.find_each do |subscriber|
      DealsMailer.weekly_digest(subscriber, deals).deliver_later
    end

    Rails.logger.info "WeeklyNewsletterJob: sent to #{Subscriber.active.count} subscribers"
  end
end
