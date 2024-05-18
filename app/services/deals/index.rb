module Deals
  class Index < ApplicationService
    attr_reader :products

    def initialize(params)
      @params = params
      @store = params[:store]
      @min_price = params[:min_price]
      @max_price = params[:max_price]
      @categories = params[:categories]
      @order = params[:order] || {}
      @products = Product.none
    end

    def call
      filter
      order_products

      self
    end

    def paginate
      @paginate ||= Pagination.new(products, params)
    end

    private

    attr_reader :store, :min_price, :max_price, :categories, :params, :order

    def filter
      scope = Product.all
      scope = scope.where(store:) if store.present?
      scope = scope.where('price >= ?', min_price) if min_price.present?
      scope = scope.where('price <= ?', max_price) if max_price.present?
      categories.present? && scope = scope.where('categories && array[?]::varchar[]', [categories].flatten)

      @products = scope
    end

    def order_products
      @products = products.order(price: order[:price]) if order[:price].present?
      @products = products.order(updated_at: order[:updated_at]) if order[:updated_at].present?
    end

  end
end
