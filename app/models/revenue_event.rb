# frozen_string_literal: true

class RevenueEvent < ApplicationRecord
  belongs_to :product, optional: true

  validates :estimated_value, presence: true

  scope :this_month, -> { where('created_at >= ?', Time.current.beginning_of_month) }
  scope :this_week,  -> { where('created_at >= ?', Time.current.beginning_of_week) }
  scope :today,      -> { where('created_at >= ?', Time.current.beginning_of_day) }

  def self.daily_totals(days: 30)
    (days - 1).downto(0).map do |d|
      date = d.days.ago.to_date
      total = where(created_at: date.beginning_of_day..date.end_of_day).sum(:estimated_value).to_f.round(4)
      { date: date.strftime('%d %b'), revenue: total }
    end
  end

  def self.top_stores(limit: 5)
    group(:store)
      .order(Arel.sql('SUM(estimated_value) DESC'))
      .limit(limit)
      .sum(:estimated_value)
      .map { |store, revenue| { store: store, revenue: revenue.to_f.round(4) } }
  end
end
