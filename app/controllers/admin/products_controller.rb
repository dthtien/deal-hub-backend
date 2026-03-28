# frozen_string_literal: true

module Admin
  class ProductsController < Admin::BaseController
    PER_PAGE = 50

    def index
      scope = Product.all
      scope = scope.where(store: params[:store]) if params[:store].present?
      scope = scope.where(expired: params[:expired] == 'true') if params[:expired].present?
      @page = (params[:page] || 1).to_i
      @total = scope.count
      @products = scope.order(created_at: :desc).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
      @stores = Product.distinct.pluck(:store).compact.sort
      @total_pages = (@total / PER_PAGE.to_f).ceil
    end

    def update
      @product = Product.find(params[:id])
      field = params[:field]
      if %w[expired featured best_deal].include?(field)
        @product.update!(field => !@product[field])
      end
      redirect_to admin_products_path(request.query_parameters.except('_method')), notice: "Product ##{@product.id} updated."
    end

    def bulk_update
      ids    = Array(params[:ids])
      action = params[:action_type].to_s
      products = Product.where(id: ids)

      case action
      when 'expire'
        products.update_all(expired: true)
      when 'feature'
        products.update_all(featured: true)
      when 'unfeature'
        products.update_all(featured: false)
      end

      redirect_to admin_products_path, notice: "#{products.count} product(s) updated."
    end

    def bulk_action
      body_params = request.content_type&.include?('application/json') ? JSON.parse(request.body.read) : params.to_unsafe_h
      ids    = Array(body_params['product_ids'] || body_params[:product_ids]).map(&:to_i)
      action = (body_params['action'] || body_params[:action]).to_s
      products = Product.where(id: ids)

      case action
      when 'mark_expired'
        products.update_all(expired: true)
        notice = "#{products.count} product(s) marked as expired."
      when 'mark_flash'
        products.update_all(flash_deal: true, flash_expires_at: 24.hours.from_now)
        notice = "#{products.count} product(s) marked as flash deals."
      when 'delete'
        count = products.count
        products.destroy_all
        notice = "#{count} product(s) deleted."
      else
        notice = "Unknown action."
      end

      render json: { message: notice }
    end

    def mark_flash
      product = Product.find(params[:id])
      product.update!(flash_deal: true, flash_expires_at: 24.hours.from_now)
      redirect_to admin_products_path, notice: "Product ##{product.id} marked as flash deal."
    end

    def clone
      original = Product.find(params[:id])
      cloned = original.dup
      cloned.name = "[COPY] #{original.name}"
      cloned.store_product_id = "#{original.store_product_id}-copy-#{SecureRandom.hex(4)}"
      cloned.save!

      original.price_histories.each do |ph|
        new_ph = ph.dup
        new_ph.product_id = cloned.id
        new_ph.save!
      end

      render json: cloned.as_json, status: :created
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Product not found' }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def bulk_expire
      body_params = request.content_type&.include?('application/json') ? JSON.parse(request.body.read) : params.to_unsafe_h

      scope = Product.all
      if body_params['store_name'].present?
        scope = scope.where(store: body_params['store_name'])
      elsif body_params['older_than_days'].to_i > 0
        cutoff = body_params['older_than_days'].to_i.days.ago
        scope = scope.where('created_at < ?', cutoff)
      else
        return render json: { error: 'Provide store_name or older_than_days' }, status: :unprocessable_entity
      end

      count = scope.where(expired: false).update_all(expired: true)
      render json: { expired_count: count, message: "#{count} product(s) marked as expired." }
    rescue JSON::ParserError
      render json: { error: 'Invalid JSON' }, status: :bad_request
    end
  end
end
