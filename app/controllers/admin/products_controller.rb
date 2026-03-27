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
      ids    = Array(params[:product_ids]).map(&:to_i)
      action = params[:action].to_s
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
  end
end
