# frozen_string_literal: true

module Api
  module V1
    class CouponsController < ApplicationController
      def index
        coupons = Coupon.active.verified_first

        if params[:store].present?
          coupons = coupons.for_store(params[:store])
        end

        render json: coupons.map { |c| coupon_json(c) }
      end

      def stores
        stores = Coupon.active
                       .select(:store)
                       .distinct
                       .order(:store)
                       .pluck(:store)
        render json: stores
      end

      def use
        coupon = Coupon.find(params[:id])
        coupon.increment!(:use_count)
        render json: { ok: true }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def track_use
        coupon = Coupon.find_by!(code: params[:code])
        coupon.increment!(:used_count)
        coupon.increment!(:use_count)
        render json: { ok: true, used_count: coupon.used_count }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      private

      def coupon_json(c)
        {
          id: c.id,
          store: c.store,
          code: c.code,
          description: c.description,
          discount_value: c.discount_value,
          discount_type: c.discount_type,
          discount_label: c.discount_label,
          expires_at: c.expires_at,
          verified: c.verified,
          use_count: c.use_count,
          used_count: c.used_count,
          minimum_spend: c.minimum_spend
        }
      end
    end
  end
end
