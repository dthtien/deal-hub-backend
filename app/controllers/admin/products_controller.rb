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
  end
end
