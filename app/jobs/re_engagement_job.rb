# frozen_string_literal: true

class ReEngagementJob < ApplicationJob
  queue_as :default

  def perform
    at_risk = Subscriber.where(segment: 'at_risk').where(status: 'active')
    deals = Product.where(expired: false).order(deal_score: :desc).limit(3).to_a

    at_risk.each do |subscriber|
      begin
        send_re_engagement(subscriber, deals)
      rescue => e
        Rails.logger.error("ReEngagementJob: error for #{subscriber.email}: #{e.message}")
      end
    end
  end

  private

  def send_re_engagement(subscriber, deals)
    last_sent = NotificationLog
      .where(recipient: subscriber.email)
      .order(created_at: :desc)
      .first

    return if last_sent && last_sent.created_at > 7.days.ago

    ReEngagementMailer.we_miss_you(subscriber, deals).deliver_now

    NotificationLog.create!(
      notification_type: 're_engagement',
      recipient: subscriber.email,
      subject: 'We miss you! Here are today\'s best deals',
      status: 'sent'
    )
  rescue => e
    NotificationLog.create!(
      notification_type: 're_engagement',
      recipient: subscriber.email,
      subject: 'We miss you! Here are today\'s best deals',
      status: 'failed'
    )
    raise e
  end
end
