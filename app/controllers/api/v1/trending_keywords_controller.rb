# frozen_string_literal: true

module Api
  module V1
    class TrendingKeywordsController < ApplicationController
      CACHE_TTL = 1.hour
      TOP_LIMIT = 20
      STOP_WORDS = %w[
        the a an and or to for in of on at by is it its with from this that are was
        were be been being have has had do does did will would could should may might
        au australia australian deal deals price
      ].freeze

      def index
        keywords = Rails.cache.fetch('trending_keywords_v2', expires_in: CACHE_TTL) do
          build_trending_keywords
        end

        render json: { keywords: keywords }
      end

      private

      def build_trending_keywords
        counts = {}

        # From search queries (recent 7 days)
        SearchQuery.where('updated_at >= ?', 7.days.ago)
                   .order(count: :desc)
                   .limit(100)
                   .each do |sq|
          words = tokenize(sq.query)
          words.each do |word|
            counts[word] = (counts[word] || 0) + sq.count.to_i
          end
        end

        # From recent product names (last 48h)
        Product.where('created_at >= ?', 48.hours.ago)
               .order(created_at: :desc)
               .limit(200)
               .pluck(:name)
               .each do |name|
          words = tokenize(name)
          words.each do |word|
            counts[word] = (counts[word] || 0) + 1
          end
        end

        # Compute trend: compare last 24h vs 24-48h for search queries
        recent_queries = SearchQuery.where('updated_at >= ?', 24.hours.ago)
                                    .pluck(:query, :count)
                                    .to_h { |q, c| [q.to_s.downcase.strip, c.to_i] }

        top = counts.sort_by { |_, v| -v }.first(TOP_LIMIT)

        top.map do |keyword, count|
          recent_count = recent_queries.sum { |q, c| tokenize(q).include?(keyword) ? c : 0 }
          trend = recent_count > 5 ? 'rising' : 'stable'
          { keyword: keyword, count: count, trend: trend }
        end
      end

      def tokenize(text)
        text.to_s
            .downcase
            .gsub(/[^a-z0-9\s]/, ' ')
            .split
            .select { |w| w.length >= 3 && !STOP_WORDS.include?(w) }
            .uniq
      end
    end
  end
end
