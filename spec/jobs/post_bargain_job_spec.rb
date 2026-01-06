require 'rails_helper'

RSpec.describe PostBargainJob, type: :job do
  describe '#perform' do
    xit do
      expect(Deals::Facebook::PostBargain).to receive(:call).and_return(
        instance_double('Deals::Facebook::PostBargain', success?: true)
      )

      described_class.new.perform
    end
  end
end
