#frozen_string_literal: true

require 'rails_helper'

RSpec.describe Deals::Facebook::PostBargain do

  describe '#call' do
    let!(:product) { create(:product, name: 'Product Title', price: 100) }
    let(:service) { described_class.new }

    before do
      allow(Facebook::Page).to receive(:new).and_return(facebook_page_double)
    end

    context 'when success' do
      let(:facebook_page_double) do
        double(
          'Facebook::Page',
          post_with_images!: double(success?: true, body: 'Success')
        )
      end

      it do
        service.call
        expect(service.success?).to be_truthy
      end
    end

    context 'when failed' do
      let(:facebook_page_double) do
        double(
          'Facebook::Page',
          post_with_images!: double(success?: false, body: 'Failed')
        )
      end

      it do
        service.call
        expect(service.success?).to be_falsey
      end
    end
  end
end
