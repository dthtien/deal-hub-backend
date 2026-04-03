# frozen_string_literal: true

module Api
  module V1
    class CategoriesController < ApplicationController
      CATEGORY_BUCKETS = [
        { name: "Women's Fashion", slug: 'womens-fashion',  keywords: %w[women dress skirt bra ladies womenswear] },
        { name: "Men's Fashion",   slug: 'mens-fashion',    keywords: %w[men polo suit mens menswear] },
        { name: 'Activewear',      slug: 'activewear',      keywords: %w[active sport gym yoga running set-active activewear] },
        { name: 'Shoes & Footwear',slug: 'shoes-footwear',  keywords: %w[shoe sneaker boot sandal footwear] },
        { name: 'Electronics',     slug: 'electronics',     keywords: %w[electronic laptop phone audio tv gaming camera] },
        { name: 'Home & Living',   slug: 'home-living',     keywords: %w[home furniture kitchen bedding bath] },
        { name: 'Beauty & Health', slug: 'beauty-health',   keywords: %w[beauty health skin fragrance vitamin] },
        { name: 'Bags & Accessories', slug: 'bags-accessories', keywords: %w[bag accessory accessories watch jewel] },
        { name: 'Outdoor & Sports',slug: 'outdoor-sports',  keywords: %w[outdoor camp hike bike swim fishing] },
        { name: 'Kids & Toys',     slug: 'kids-toys',       keywords: %w[kid toy baby child junior] }
      ].freeze

      def index
        response.set_header('Cache-Control', 'public, max-age=600')

        categories = Rails.cache.fetch('categories_v2', expires_in: 10.minutes) do
          Product.where(expired: false)
                 .where.not(categories: nil)
                 .pluck(:categories)
                 .flatten
                 .tally
                 .sort_by { |_, v| -v }
                 .first(10)
                 .map { |name, count| { name: name, deal_count: count } }
        end

        render json: { categories: categories }
      end

      def trending
        response.set_header('Cache-Control', 'public, max-age=300')

        now = Time.current
        current_window_start  = now - 24.hours
        previous_window_start = now - 48.hours

        current_counts  = Hash.new(0)
        previous_counts = Hash.new(0)

        CATEGORY_BUCKETS.each do |bucket|
          kws = bucket[:keywords]
          # current 24h
          Product.where('created_at >= ?', current_window_start)
                 .where(kws.map { "categories::text ILIKE ?" }.join(' OR '), *kws.map { |k| "%#{k}%" })
                 .count.tap { |c| current_counts[bucket[:name]] = c }
          # previous 24h
          Product.where('created_at >= ? AND created_at < ?', previous_window_start, current_window_start)
                 .where(kws.map { "categories::text ILIKE ?" }.join(' OR '), *kws.map { |k| "%#{k}%" })
                 .count.tap { |c| previous_counts[bucket[:name]] = c }
        end

        trending = CATEGORY_BUCKETS.map do |bucket|
          name     = bucket[:name]
          current  = current_counts[name]
          previous = previous_counts[name]
          growth   = current - previous
          growth_pct = if previous > 0
                         ((current - previous).to_f / previous * 100).round(1)
                       elsif current > 0
                         100.0
                       else
                         0.0
                       end
          { name: name, slug: bucket[:slug], new_count: current, growth: growth, growth_pct: growth_pct }
        end
        .select { |c| c[:growth] > 0 }
        .sort_by { |c| -c[:growth] }
        .first(5)

        render json: { categories: trending }
      end

      def top_deals
        category = CGI.unescape(params[:name].to_s)

        products = Rails.cache.fetch("category_top_deals_#{category}", expires_in: 1.hour) do
          Product.where('categories @> ARRAY[?]::varchar[]', category)
                 .where(expired: false)
                 .order(deal_score: :desc)
                 .limit(10)
                 .map(&:as_json)
        end

        render json: { products: products }
      end

      private

      def map_to_bucket(raw)
        lower = raw.to_s.downcase.strip
        CATEGORY_BUCKETS.each do |bucket|
          return bucket[:name] if bucket[:keywords].any? { |kw| lower.include?(kw) }
        end
        nil
      end
    end
  end
end
