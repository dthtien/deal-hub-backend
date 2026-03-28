# frozen_string_literal: true

module Api
  module V1
    class CartController < ApplicationController
      # Hardcoded shipping thresholds (AUD). nil means free shipping always.
      SHIPPING_RATES = {
        Product::OFFICE_WORKS      => { fee: 9.95,  free_threshold: 55 },
        Product::JB_HIFI           => { fee: 7.95,  free_threshold: 49 },
        Product::GLUE_STORE        => { fee: 8.95,  free_threshold: 60 },
        Product::NIKE              => { fee: 9.95,  free_threshold: 150 },
        Product::CULTURE_KINGS     => { fee: 9.95,  free_threshold: 100 },
        Product::JD_SPORTS         => { fee: 9.95,  free_threshold: 100 },
        Product::MYER              => { fee: 9.95,  free_threshold: 49 },
        Product::THE_GOOD_GUYS     => { fee: 0,     free_threshold: 0 },
        Product::ASOS              => { fee: 0,     free_threshold: 0 },
        Product::THE_ICONIC        => { fee: 0,     free_threshold: 0 },
        Product::KMART             => { fee: 0,     free_threshold: 0 },
        Product::BIG_W             => { fee: 0,     free_threshold: 0 },
        Product::TARGET_AU         => { fee: 0,     free_threshold: 0 },
        Product::BOOKING_COM       => { fee: 0,     free_threshold: 0 },
        Product::GOOD_BUYZ         => { fee: 9.95,  free_threshold: 99 },
        Product::BEGINNING_BOUTIQUE => { fee: 8.95, free_threshold: 80 },
        Product::UNIVERSAL_STORE   => { fee: 7.95,  free_threshold: 80 },
        Product::LORNA_JANE        => { fee: 8.00,  free_threshold: 99 }
      }.freeze

      def estimate
        product_ids = Array(params[:product_ids]).map(&:to_i).uniq
        if product_ids.empty?
          return render json: { error: 'product_ids required' }, status: :unprocessable_entity
        end

        products = Product.where(id: product_ids, expired: false).to_a
        found_ids = products.map(&:id)
        missing_ids = product_ids - found_ids

        # Group items by store, pick cheapest store per product
        # Build store -> items map using cheapest item per product across stores
        cheapest_by_product = {}
        products.each do |p|
          cheapest_by_product[p.id] ||= p
          if p.price.to_f < cheapest_by_product[p.id].price.to_f
            cheapest_by_product[p.id] = p
          end
        end

        # Calculate store baskets for cheapest combo
        store_baskets = Hash.new { |h, k| h[k] = [] }
        cheapest_by_product.each_value { |p| store_baskets[p.store] << p }

        total_cost = 0.0
        total_rrp  = 0.0
        store_breakdown = []

        store_baskets.each do |store, items|
          subtotal = items.sum { |p| p.price.to_f }
          rrp_subtotal = items.sum { |p| [p.old_price.to_f, p.price.to_f].max }
          shipping_info = SHIPPING_RATES[store] || { fee: 9.95, free_threshold: 50 }
          shipping_cost = subtotal >= shipping_info[:free_threshold] ? 0.0 : shipping_info[:fee].to_f

          store_total = subtotal + shipping_cost
          total_cost  += store_total
          total_rrp   += rrp_subtotal

          store_breakdown << {
            store: store,
            items: items.map { |p| { id: p.id, name: p.name, price: p.price.to_f, old_price: p.old_price.to_f } },
            subtotal: subtotal.round(2),
            shipping_cost: shipping_cost.round(2),
            store_total: store_total.round(2),
            free_shipping_from: shipping_info[:free_threshold]
          }
        end

        total_savings = [total_rrp - total_cost, 0].max

        render json: {
          product_ids: found_ids,
          missing_product_ids: missing_ids,
          stores_needed: store_baskets.keys,
          store_breakdown: store_breakdown,
          total_cost: total_cost.round(2),
          total_rrp: total_rrp.round(2),
          total_savings: total_savings.round(2),
          cheapest_combo: store_breakdown.sort_by { |s| s[:store_total] }
        }
      end
    end
  end
end
