# frozen_string_literal: true

module Api
  module V1
    class SeoController < ApplicationController
      def best_price
        slug = params[:slug].to_s.strip.downcase
        # Convert slug back to searchable terms
        search_terms = slug.gsub('-', ' ')

        cache_key = "seo_best_price_v1_#{slug}"
        data = Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          # Find products matching the slug
          products = Product.where(expired: false)
                            .where("LOWER(name) ILIKE ?", "%#{search_terms}%")
                            .order(price: :asc)
                            .limit(20)

          if products.empty?
            return render json: { error: 'Not found' }, status: :not_found
          end

          best = products.first
          cheapest_price = products.minimum(:price)
          highest_price  = products.maximum(:price)

          # Price history for the best match
          histories = best.price_histories
                          .order(recorded_at: :desc)
                          .limit(30)
                          .map { |h| { price: h.price, recorded_at: h.recorded_at } }

          # Group by store for comparison
          by_store = products.group_by(&:store).map do |store, prods|
            p = prods.min_by(&:price)
            {
              store: store,
              price: p.price,
              old_price: p.old_price,
              discount: p.discount,
              url: p.store_url,
              image_url: p.image_url,
              deal_id: p.id
            }
          end.sort_by { |s| s[:price].to_f }

          lowest_ever = histories.map { |h| h[:price] }.min || cheapest_price

          {
            slug: slug,
            name: best.name,
            search_term: search_terms,
            current_best_price: cheapest_price,
            highest_price: highest_price,
            lowest_ever_price: lowest_ever,
            savings_vs_highest: ((highest_price.to_f - cheapest_price.to_f) / highest_price.to_f * 100).round(1),
            product_count: products.count,
            stores: by_store,
            price_history: histories,
            best_deal: {
              id: best.id,
              name: best.name,
              price: best.price,
              old_price: best.old_price,
              discount: best.discount,
              store: best.store,
              image_url: best.image_url,
              store_url: best.store_url,
              categories: best.categories
            }
          }
        end

        render json: data
      end

      def popular_searches
        # Return top product name slugs for sitemap generation
        cache_key = 'seo_popular_searches_v1'
        data = Rails.cache.fetch(cache_key, expires_in: 6.hours) do
          Product.where(expired: false)
                 .where('view_count > 0 OR deal_score > 5')
                 .order(deal_score: :desc, view_count: :desc)
                 .limit(500)
                 .pluck(:name)
                 .uniq
                 .map { |name| name.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/-+/, '-').gsub(/^-|-$/, '') }
                 .uniq
        end
        render json: { slugs: data }
      end
    end
  end
end
