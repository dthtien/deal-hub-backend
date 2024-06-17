# frozen_string_literal: true

module Insurances
  class CompareTheMarketJob < ApplicationGushJob
    def perform
      quote_id = params[:quote_id]
      quote = Quote.find(quote_id)
      return if quote.failed? || quote.completed?

      service = Insurances::CompareTheMarket::Quote.new(quote).call
      return if service.success?

      ExceptionNotifier.notify_exception(
        StandardError.new(service.errors.to_sentence),
        data: { service: }
      )
      quote.update!(status: Quote::FAILED)
    end
  end
end

