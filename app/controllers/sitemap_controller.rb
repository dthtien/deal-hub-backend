# frozen_string_literal: true

class SitemapController < ApplicationController
  def index
    @products = Product.select(:id, :name, :updated_at).order(updated_at: :desc).limit(1000)

    respond_to do |format|
      format.xml
    end
  end
end
