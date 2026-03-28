# frozen_string_literal: true

module Admin
  class AbTestsController < BaseController
    # GET /admin/ab_tests
    def index
      # Use product ab_variant field as experiment data
      # Experiment: "deal_display" with variants A/B based on ab_variant column
      # Conversion proxy: products with ab_variant that got clicks

      variant_counts = Product
        .where(expired: false)
        .where.not(ab_variant: nil)
        .group(:ab_variant)
        .count

      # Click-through per variant (using click_trackings joined to products)
      variant_clicks = Product
        .joins(:click_trackings)
        .where.not(ab_variant: nil)
        .group('products.ab_variant')
        .count

      experiments = {}

      variant_counts.each do |variant, total|
        clicks = variant_clicks[variant].to_i
        rate   = total > 0 ? (clicks.to_f / total * 100).round(2) : 0.0

        experiments['deal_display'] ||= { variants: [], winner: nil, significant: false }
        experiments['deal_display'][:variants] << {
          variant: variant,
          samples: total,
          conversions: clicks,
          conversion_rate: rate
        }
      end

      # Determine significance + winner per experiment
      experiments.each do |_name, exp|
        variants = exp[:variants].sort_by { |v| -v[:conversion_rate] }
        exp[:variants] = variants

        if variants.size >= 2
          best   = variants[0]
          second = variants[1]
          diff   = (best[:conversion_rate] - second[:conversion_rate]).abs
          sig    = best[:samples] > 100 && second[:samples] > 100 && diff > 5.0

          exp[:significant] = sig
          exp[:winner]      = sig ? best[:variant] : nil
          exp[:difference]  = diff.round(2)
        end
      end

      render json: { experiments: experiments }
    end
  end
end
