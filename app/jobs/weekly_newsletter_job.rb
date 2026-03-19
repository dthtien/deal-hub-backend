# frozen_string_literal: true

class WeeklyNewsletterJob < ApplicationJob
  def perform
    deals = Product
      .order(discount: :desc)
      .where('updated_at >= ?', 7.days.ago)
      .limit(10)

    return if deals.empty?

    Subscriber.active.find_each do |subscriber|
      DealsMailer.weekly_digest(subscriber, deals).deliver_later
    end

    Rails.logger.info "WeeklyNewsletterJob: sent to #{Subscriber.active.count} subscribers"
  end
end
