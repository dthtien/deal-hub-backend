class Product < ApplicationRecord
  has_many :click_trackings, dependent: :destroy

  def click_count
    click_trackings.count
  end
end
