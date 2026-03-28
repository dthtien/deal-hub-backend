# frozen_string_literal: true

module Admin
  class CouponGenerateController < BaseController
    CHARS = ('A'..'Z').to_a + ('0'..'9').to_a

    def create
      store         = params[:store].to_s.strip
      discount_type = params[:discount_type].to_s
      discount_value = params[:discount_value].to_f
      count         = [[params[:count].to_i, 1].max, 100].min
      expires_at    = params[:expires_at].present? ? Time.zone.parse(params[:expires_at]) : nil

      unless store.present?
        return render json: { error: 'store is required' }, status: :unprocessable_entity
      end

      unless %w[percent fixed].include?(discount_type)
        return render json: { error: 'discount_type must be percent or fixed' }, status: :unprocessable_entity
      end

      created = []
      attempts = 0
      max_attempts = count * 10

      while created.size < count && attempts < max_attempts
        attempts += 1
        code = generate_code
        next if Coupon.exists?(code: code)

        coupon = Coupon.create!(
          store: store,
          code: code,
          discount_type: discount_type,
          discount_value: discount_value,
          expires_at: expires_at,
          active: true,
          used_count: 0
        )
        created << coupon
      end

      render json: { coupons: created.map { |c| coupon_json(c) }, count: created.size }
    end

    private

    def generate_code
      Array.new(8) { CHARS.sample }.join
    end

    def coupon_json(coupon)
      {
        id: coupon.id,
        code: coupon.code,
        store: coupon.store,
        discount_type: coupon.discount_type,
        discount_value: coupon.discount_value,
        expires_at: coupon.expires_at,
        active: coupon.active
      }
    end
  end
end
