class PushSubscription < ApplicationRecord
  validates :endpoint, presence: true, uniqueness: true
  validates :p256dh, presence: true
  validates :auth, presence: true

  def to_webpush_subscription
    {
      endpoint: endpoint,
      keys: { p256dh: p256dh, auth: auth }
    }
  end
end
