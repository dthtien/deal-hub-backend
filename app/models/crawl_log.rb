# frozen_string_literal: true

class CrawlLog < ApplicationRecord
  validates :store, presence: true
end
