# frozen_string_literal: true

module Admin
  class CouponsController < BaseController
    before_action :set_coupon, only: %i[edit update destroy]

    def index
      @coupons = Coupon.order(created_at: :desc)
    end

    def new
      @coupon = Coupon.new
    end

    def create
      @coupon = Coupon.new(coupon_params)
      if @coupon.save
        redirect_to admin_coupons_path, notice: 'Coupon created.'
      else
        render :new
      end
    end

    def edit; end

    def update
      if @coupon.update(coupon_params)
        redirect_to admin_coupons_path, notice: 'Coupon updated.'
      else
        render :edit
      end
    end

    def destroy
      @coupon.destroy
      redirect_to admin_coupons_path, notice: 'Coupon deleted.'
    end

    private

    def set_coupon
      @coupon = Coupon.find(params[:id])
    end

    def coupon_params
      params.require(:coupon).permit(
        :store, :code, :description, :discount_value, :discount_type,
        :expires_at, :verified, :active, :minimum_spend
      )
    end
  end
end
