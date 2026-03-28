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
      @states = params[:states] || (params[:state].present? ? { '0' => params[:state] } : nil)
      @tags = params[:tags]
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
                :query, :with_order, :states, :tags

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

      q = query.strip
      conn = ActiveRecord::Base.connection

      # Use full-text search with search_vector if available, fallback to ILIKE
      tsquery = q.split.map { |w| conn.quote(w + ':*') }.join(' & ')

      @products = @products.where(
        "search_vector @@ to_tsquery('english', ?) OR name ILIKE ? OR brand ILIKE ? OR description ILIKE ?",
        tsquery.gsub("'", "''"),
        "%#{q}%",
        "%#{q}%",
        "%#{q}%"
      )

      quoted = conn.quote(q.downcase)
      rank_sql = Arel.sql(<<~SQL.squish)
        (
          CASE WHEN search_vector IS NOT NULL
            THEN ts_rank(search_vector, to_tsquery('english', #{conn.quote(tsquery.gsub("'", "''"))})) * 10
            ELSE 0 END +
          CASE WHEN LOWER(name) = #{quoted} THEN 10 ELSE 0 END +
          CASE WHEN LOWER(name) LIKE #{conn.quote("%#{q.downcase}%")} AND LOWER(name) != #{quoted} THEN 5 ELSE 0 END +
          CASE WHEN LOWER(COALESCE(brand,'')) LIKE #{conn.quote("%#{q.downcase}%")} THEN 3 ELSE 0 END
        ) DESC, deal_score DESC
      SQL

      @products = @products.order(rank_sql)
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

      state_values = states.is_a?(Hash) ? [states.values].flatten : Array(states)
      state_values = state_values.compact.map(&:to_s).select(&:present?)
      return if state_values.empty?

      # Products with empty available_states are available everywhere
      # Products with non-empty available_states must include the requested state
      @products = products.where(
        'available_states = \'{}\' OR available_states && array[?]::varchar[]',
        state_values
      )
    end

    def filter_by_tags
      return if tags.blank?

      tag_list = tags.is_a?(Hash) ? [tags.values].flatten : Array(tags)
      return if tag_list.empty?

      @products = products.where('tags && array[?]::varchar[]', tag_list)
    end

    def filter
      @products = Product.includes(:ai_deal_analysis).where(expired: false)
      # Default: only in-stock products; pass include_out_of_stock=true to override
      unless @params[:include_out_of_stock].present?
        @products = @products.where(in_stock: true)
      end
      filter_by_status
      filter_by_brands
      filter_by_categories
      filter_by_price
      filter_by_min_discount
      filter_by_stores
      filter_by_states
      filter_by_tags
    end

    def filter_by_status
      return if @params[:status].blank?
      @products = @products.where(status: @params[:status])
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

      # A/B variant sorting:
      # Variant A (default): sort by deal_score desc
      # Variant B: sort by view_count desc (more viral/trending focused)
      if @params[:ab_variant] == 'B'
        @products = products.order(view_count: :desc)
        return
      end

      order_by_date
      @products = products.order(price: order[:price]) if order[:price].present?
      @products = products.order(discount: order[:discount]) if order[:discount].present?
      @products = products.order(deal_score: order[:deal_score] || :desc) if order[:deal_score].present?
    end
  end
end
