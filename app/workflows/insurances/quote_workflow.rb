# frozen_string_literal: true

module Insurances
  class QuoteWorkflow < ApplicationWorkflow
    def configure(quote_id)
      run Insurances::StartJob, params: { quote_id: }
      run Insurances::AamiJob, params: { quote_id: }, after: [Insurances::StartJob]
      run Insurances::CompareTheMarketJob, params: { quote_id: }, after: [Insurances::StartJob]
      run Insurances::FinishJob, params: { quote_id: }, after: [Insurances::AamiJob, Insurances::CompareTheMarketJob]
    end
  end
end
