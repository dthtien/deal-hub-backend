# frozen_string_literal: true

require 'csv'

module Api
  module V1
    class PriceHistoriesController < ApplicationController
      include ActionController::MimeResponds

      def index
        product = Product.find(params[:deal_id])

        respond_to do |format|
          format.json { render json: price_histories_json(product) }

          format.csv do
            histories = product.price_histories.order(recorded_at: :desc).limit(365)
            csv_data = CSV.generate(headers: true) do |csv|
              csv << %w[date price old_price recorded_at]
              histories.each do |h|
                csv << [
                  h.recorded_at&.to_date,
                  h.price,
                  h.old_price,
                  h.recorded_at
                ]
              end
            end
            send_data csv_data,
                      type: 'text/csv',
                      disposition: "attachment; filename=\"price-history-#{product.id}.csv\""
          end

          # Like the rest of the API, answer JSON when no known format is asked for
          # (crawlers and browsers arrive as HTML and used to get UnknownFormat).
          format.any { render json: price_histories_json(product) }
        end
      end

      private

      def price_histories_json(product)
        histories = product.price_histories.recent.limit(30)
        {
          price_histories: histories.map { |h|
            {
              price: h.price,
              old_price: h.old_price,
              discount: h.discount,
              recorded_at: h.recorded_at
            }
          }
        }
      end
    end
  end
end
