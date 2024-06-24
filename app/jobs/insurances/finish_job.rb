# frozen_string_literal: true

module Insurances
  class FinishJob < ApplicationGushJob
    def perform
      quote_id = params[:quote_id]
      quote = Quote.find(quote_id)
      return if quote.failed? || quote.completed?

      quote.update!(status: Quote::COMPLETED)
    end
  end
end
