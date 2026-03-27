# frozen_string_literal: true

module Api
  module V1
    class TagsController < ApplicationController
      def index
        tags = Rails.cache.fetch('all_tags_v1', expires_in: 10.minutes) do
          Product.where(expired: false)
                 .where("tags IS NOT NULL AND array_length(tags, 1) > 0")
                 .pluck(:tags)
                 .flatten
                 .compact
                 .reject(&:empty?)
                 .tally
                 .sort_by { |_, count| -count }
                 .map { |tag, count| { tag: tag, count: count } }
        end

        render json: { tags: tags }
      end
    end
  end
end
