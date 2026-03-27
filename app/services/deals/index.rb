module Deals
  class Index < ApplicationService
    attr_reader :products

    def initialize(params, with_order: true)
      @params = params
      @stores = params[:stores]
      @min_price = params[:min_price]
      @max_price = params[:max_price]
      @min_discount = params[:min_discount]
      @categories = params[:categories]
      @query = params[:query]
      @brands = params[:brands]
      @states = params[:states]
      @order = params[:order] || {}
      @products = Product.none
      @with_order = with_order
    end

    def call
      filter
      order_products
      query_data
      track_search

      self
    end

    def paginate
      @paginate ||= Pagination.new(products, params)
    end

    private

    attr_reader :stores, :min_price, :max_price, :min_discount, :categories, :params, :order, :brands,
                :query, :with_order, :states

    def filter_by_brands
      @products = products.where(brand: [brands.values].flatten) if brands.present?
    end

    def filter_by_stores
      return if stores.blank?
      store_list = stores.is_a?(Hash) ? [stores.values].flatten : Array(stores)
      @products = products.where(store: store_list)
    end

    def query_data
      return if query.blank?

      @products = @products.where('name ILIKE ?', "%#{query}%")
                           .or(@products.where('description ILIKE ?', "%#{query}%"))
                           .or(@products.where('brand ILIKE ?', "%#{query}%"))
    end

    def filter_by_categories
      return if categories.blank?

      cat_list = categories.is_a?(Hash) ? [categories.values].flatten : Array(categories)
      @products = @products.where('categories && array[?]::varchar[]', cat_list)
    end

    def filter_by_min_discount
      return if min_discount.blank?
      @products = @products.where('discount >= ?', min_discount.to_f)
    end

    def filter_by_price
      @products = products.where('price >= ?', min_price) if min_price.present?
      @products = products.where('price <= ?', max_price) if max_price.present?
    end

    def filter_by_states
      return if states.blank?

      state_values = [states.values].flatten
      @products = products.where('available_states && array[?]::varchar[]', state_values)
    end

    def filter
      @products = Product.includes(:ai_deal_analysis).where(expired: false)
      filter_by_brands
      filter_by_categories
      filter_by_price
      filter_by_min_discount
      filter_by_stores
      filter_by_states
    end

    def track_search
      SearchQuery.track(query) if query.present?
    end

    def order_by_date
      return @products = products.order(updated_at: order[:updated_at]) if order[:updated_at].present?
      return @products = products.order(created_at: order[:created_at]) if order[:created_at].present?

      @products = products.order(updated_at: :desc) if order.empty?
    end

    def order_products
      return unless with_order

      order_by_date
      @products = products.order(price: order[:price]) if order[:price].present?
      @products = products.order(discount: order[:discount]) if order[:discount].present?
      @products = products.order(deal_score: order[:deal_score] || :desc) if order[:deal_score].present?
    end
  end
end
