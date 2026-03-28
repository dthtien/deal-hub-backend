class ClickTracking < ApplicationRecord
  belongs_to :product

  validates :product_id, presence: true

  scope :recent, -> { order(clicked_at: :desc) }
  scope :by_store, ->(store) { where(store: store) }
  scope :today, -> { where(clicked_at: Time.current.beginning_of_day..) }
  scope :with_utm, -> { where.not(utm_source: nil) }

  # Parse UTM params from a URL query string
  def self.utm_from_url(url)
    return {} if url.blank?
    uri = URI.parse(url)
    params = URI.decode_www_form(uri.query || '').to_h
    {
      utm_source:   params['utm_source'],
      utm_medium:   params['utm_medium'],
      utm_campaign: params['utm_campaign']
    }.compact
  rescue URI::InvalidURIError
    {}
  end
end
