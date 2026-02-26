# frozen_string_literal: true

module Admin
  class AffiliateConfigsController < BaseController
    before_action :set_config, only: %i[edit update destroy]

    def index
      @configs = AffiliateConfig.order(:store)
      @stores = Product::STORES - AffiliateConfig.pluck(:store)
    end

    def new
      @config = AffiliateConfig.new
    end

    def create
      @config = AffiliateConfig.new(config_params)
      if @config.save
        redirect_to admin_affiliate_configs_path, notice: 'Affiliate config created!'
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      if @config.update(config_params)
        redirect_to admin_affiliate_configs_path, notice: 'Updated!'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @config.destroy
      redirect_to admin_affiliate_configs_path, notice: 'Deleted.'
    end

    private

    def set_config
      @config = AffiliateConfig.find(params[:id])
    end

    def config_params
      params.require(:affiliate_config).permit(:store, :param_name, :param_value, :active)
    end
  end
end
