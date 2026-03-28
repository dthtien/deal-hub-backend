# frozen_string_literal: true

class SegmentSubscribersJob < ApplicationJob
  queue_as :default

  def perform
    now = Time.current

    Subscriber.find_each do |subscriber|
      segment = determine_segment(subscriber, now)
      subscriber.update_column(:segment, segment) if subscriber.segment != segment
    end
  end

  private

  def determine_segment(subscriber, now)
    age_days = (now - subscriber.confirmed_at).to_i / 86400 rescue nil
    age_days ||= (now - subscriber.created_at).to_i / 86400

    if age_days < 7
      'new'
    elsif age_days <= 30
      'active'
    elsif age_days <= 90
      'at_risk'
    else
      'churned'
    end
  end
end
