module Deals
  class Index < ApplicationService
    attr_reader :products

    def initialize(params, with_order: true)
      @params = params
      @stores = params[:stores]
      @min_price = params[:min_price]
      @max_price = params[:max_price]
      @categories = params[:categories]
      @query = params[:query]
      @brands = params[:brands]
      @order = params[:order] || {}
      @products = Product.none
      @with_order = with_order
    end

    def call
      filter
      order_products
      query_data

      self
    end

    def paginate
      @paginate ||= Pagination.new(products, params)
    end

    private

    attr_reader :stores, :min_price, :max_price, :categories, :params, :order, :brands,
                :query, :with_order

    def filter_by_brands
      @products = products.where(brand: [brands.values].flatten) if brands.present?
    end

    def filter_by_stores
      @products = products.where(store: [stores.values].flatten) if stores.present?
    end

    def query_data
      return if query.blank?

      @products = @products.where('name ILIKE ?', "%#{query}%")
                           .or(@products.where('description ILIKE ?', "%#{query}%"))
                           .or(@products.where('brand ILIKE ?', "%#{query}%"))
                           .or(@products.where('categories::text iLIKE ?', "%#{query}%"))
    end

    def filter_by_categories
      return if categories.blank?

      @products = @products.where('categories && array[?]::varchar[]', [categories.values].flatten)
    end

    def filter_by_price
      @products = products.where('price >= ?', min_price) if min_price.present?
      @products = products.where('price <= ?', max_price) if max_price.present?
    end

    def filter
      @products = Product.all
      filter_by_brands
      filter_by_categories
      filter_by_price
      filter_by_stores
    end

    def order_products
      return unless with_order

      @products = products.order(price: order[:price]) if order[:price].present?
      return @products = products.order(updated_at: order[:updated_at]) if order[:updated_at].present?
      return @products = products.order(created_at: order[:created_at]) if order[:created_at].present?

      @products = products.order(created_at: :desc)
    end
  end
end
