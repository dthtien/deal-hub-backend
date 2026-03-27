# frozen_string_literal: true

require 'csv'

module Api
  module V1
    class PriceHistoriesController < ApplicationController
      def index
        product = Product.find(params[:deal_id])

        respond_to do |format|
          format.json do
            histories = product.price_histories.recent.limit(30)
            render json: {
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
        end
      end
    end
  end
end
