# frozen_string_literal: true
require 'cgi'

class SitemapController < ActionController::Base
  SITE_URL = 'https://www.ozvfy.com'

  def index
    @products   = Product.where(expired: false).select(:id, :updated_at).order(updated_at: :desc).limit(5000)
    @stores     = Product.distinct.pluck(:store).compact.sort
    @categories = Product.where("array_length(categories, 1) > 0")
                         .pluck(:categories)
                         .flatten
                         .tally
                         .sort_by { |_, c| -c }
                         .first(50)
                         .map(&:first)
    @searches   = SearchQuery.trending(limit: 50).pluck(:query)

    render 'index', formats: [:xml], layout: false, content_type: 'application/xml'
  end
end
