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
        response.set_header('Cache-Control', 'public, max-age=3600')

        raw_categories = Product.where(expired: false)
                                .pluck('DISTINCT(categories)')
                                .flatten
                                .uniq
                                .compact

        # Count products per bucket
        bucket_counts = Hash.new(0)
        raw_categories.each do |raw|
          bucket = map_to_bucket(raw)
          next unless bucket

          count = Product.where(expired: false)
                         .where('categories @> ARRAY[?]::varchar[]', raw)
                         .count
          bucket_counts[bucket] += count
        end

        categories = CATEGORY_BUCKETS.map do |bucket|
          { name: bucket[:name], slug: bucket[:slug], count: bucket_counts[bucket[:name]] }
        end.select { |c| c[:count] > 0 }
           .sort_by { |c| -c[:count] }

        render json: { categories: categories }
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
