# frozen_string_literal: true

class MerchantFeedController < ApplicationController
  SITE_URL = 'https://www.ozvfy.com'

  def index
    @products = Product.where(expired: false)
                       .where.not(image_url: [nil, ''])
                       .where('price > 0')
                       .order(discount: :desc, updated_at: :desc)
                       .limit(10_000)

    respond_to do |format|
      format.xml { render layout: false }
    end
  end
end
