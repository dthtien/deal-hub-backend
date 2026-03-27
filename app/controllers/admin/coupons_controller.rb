# frozen_string_literal: true

require 'csv'

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

    def import
      return unless request.post?

      file = params[:file]
      if file.blank?
        flash[:alert] = 'Please select a CSV file.'
        return
      end

      created = 0
      skipped = 0
      CSV.parse(file.read, headers: true) do |row|
        store = row['store'].to_s.strip
        code  = row['code'].to_s.strip
        next if store.blank? || code.blank?

        coupon = Coupon.find_or_initialize_by(store: store, code: code)
        if coupon.new_record?
          coupon.assign_attributes(
            description:    row['description'],
            discount_value: row['discount_value'],
            discount_type:  row['discount_type'],
            expires_at:     row['expires_at'].present? ? Time.zone.parse(row['expires_at']) : nil,
            verified:       row['verified'].to_s.strip.downcase == 'true',
            active:         true
          )
          coupon.save ? created += 1 : skipped += 1
        else
          skipped += 1
        end
      end

      flash[:notice] = "Import complete: #{created} created, #{skipped} skipped."
      redirect_to admin_coupons_path
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
