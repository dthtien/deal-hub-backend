# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Referral, type: :model do
  describe 'validations' do
    it 'is valid with a code and defaults' do
      r = Referral.new(code: 'ABCD1234', session_id: 'sess1', click_count: 0, conversion_count: 0)
      expect(r).to be_valid
    end

    it 'requires non-negative conversion_count' do
      r = Referral.new(code: 'XYZ', session_id: 's', click_count: 0, conversion_count: -1)
      expect(r).not_to be_valid
    end
  end

  describe '#estimated_reward' do
    it 'returns conversion_count * 5' do
      r = Referral.new(conversion_count: 3)
      expect(r.estimated_reward).to eq(15)
    end

    it 'returns 0 when no conversions' do
      r = Referral.new(conversion_count: 0)
      expect(r.estimated_reward).to eq(0)
    end
  end

  describe '#record_conversion!' do
    it 'increments conversion_count and sets converted_at' do
      r = Referral.create!(session_id: SecureRandom.hex, click_count: 0, conversion_count: 0)
      expect { r.record_conversion! }.to change { r.reload.conversion_count }.by(1)
      expect(r.converted_at).not_to be_nil
    end

    it 'does not overwrite converted_at on second conversion' do
      r = Referral.create!(session_id: SecureRandom.hex, click_count: 0, conversion_count: 0)
      r.record_conversion!
      original_time = r.converted_at
      r.record_conversion!
      expect(r.reload.converted_at.to_i).to eq(original_time.to_i)
    end
  end

  describe '.find_or_create_for_session' do
    it 'creates a new referral for unknown session' do
      expect {
        Referral.find_or_create_for_session('new-session-xyz')
      }.to change(Referral, :count).by(1)
    end

    it 'finds existing referral for known session' do
      r = Referral.create!(session_id: 'known-session', click_count: 0, conversion_count: 0)
      found = Referral.find_or_create_for_session('known-session')
      expect(found.id).to eq(r.id)
    end
  end
end
