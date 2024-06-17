# frozen_string_literal: true

require 'rails_helper'

describe Insurances::AamiJob do
  describe '#perform' do
    let!(:quote) { create(:quote, status: Quote::INITIATED) }
    let(:job) { described_class.new }
    before do
      expect_any_instance_of(described_class)
        .to receive(:params).and_return({ quote_id: quote.id })
    end


    context 'when success' do
      let(:quote_service) do
        instance_double(Insurances::Suncorp::Quote, call: double(success?: true, data: {}))
      end

      it do
        expect(Insurances::Suncorp::Quote).to receive(:new).and_return(quote_service)
        job.perform
        quote.reload
      end
    end

    context 'when failed' do
      let(:quote_service) do
        instance_double(Insurances::Suncorp::Quote, call: double(success?: false, errors: ['Error']))
      end

      it do
        expect(Insurances::Suncorp::Quote).to receive(:new).and_return(quote_service)
        expect(ExceptionNotifier).to receive(:notify_exception)
        job.perform
        quote.reload

        expect(quote.failed?).to be_truthy
      end
    end
  end
end
