# frozen_string_literal: true

module Deals
  module Facebook
    class PostBargain < ApplicationService
      attr_reader :errors

      def initialize
        @errors = []
      end

      def call
        Product::STORES.each do |store|
          bargain = bargain_by_store(store)
          next if bargain.blank?

          response = post_bargain(bargain)
          @errors << "Unable to post: #{response.body}" unless response.success?
        end

        self
      end

      def success?
        errors.blank?
      end

      private

      def fb_page
        @fb_page ||= ::Facebook::Page.new
      end

      def post_bargain(bargain)
        fb_page.post_with_images!(message(bargain), images(bargain))
      rescue StandardError => e
        OpenStruct.new(body: e.message, success?: false)
      end

      def current_time
        @current_time ||= Time.current
      end

      def bargain_by_store(store)
        bargains.find_by(store:)
      end

      def bargains
        @bargains ||= Product.where(
          created_at: [current_time.beginning_of_day..current_time.end_of_day]
        ).order(discount: :desc)
      end

      def images(bargain)
        image_url = bargain.image_url

        return if image_url.blank?
        return ["https:#{image_url}"] if image_url.present? && image_url.start_with?('//')

        [image_url]
      end

      def message(bargain)
        price_text = "Price: $#{bargain.price}"
        price_text += " (was $#{bargain.old_price})" if bargain.old_price&.positive?
        price_text += " - discount #{bargain.discount}%" if bargain.discount&.positive?

        "🎉🎉🎉 Good deal 🎉🎉🎉\n\n"\
        "👉 #{bargain.name}\n"\
        "👉 #{current_time.strftime('%d/%m/%Y')}\n"\
        "👉 #{price_text}\n"\
        "👉 #{bargain.store_url}\n"\
        "👉 More deals at #{ENV['APP_URL']}"
      end
    end
  end
end
