# frozen_string_literal: true

class WeeklyStoreReportJob
  include Sidekiq::Job

  queue_as :low

  def perform
    admin_email = ENV.fetch('ADMIN_EMAIL', 'admin@ozvfy.com')
    week_ago = 1.week.ago

    total_deals = Product.where(expired: false).count

    top_stores = ClickTracking
      .joins(:product)
      .where(products: { expired: false })
      .group('products.store')
      .order('count_all desc')
      .limit(10)
      .count

    zero_new_stores = Product.distinct.pluck(:store).compact.select do |store|
      Product.where(store: store).where('created_at >= ?', week_ago).count == 0
    end

    WeeklyStoreReportMailer.weekly_report(
      admin_email,
      top_stores: top_stores,
      zero_new_stores: zero_new_stores,
      total_deal_count: total_deals
    ).deliver_later
  end
end
