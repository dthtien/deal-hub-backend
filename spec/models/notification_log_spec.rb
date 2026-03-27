require 'rails_helper'

RSpec.describe NotificationLog, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      log = build(:notification_log)
      expect(log).to be_valid
    end

    it 'requires notification_type' do
      log = build(:notification_log, notification_type: '')
      expect(log).not_to be_valid
    end

    it 'requires recipient' do
      log = build(:notification_log, recipient: '')
      expect(log).not_to be_valid
    end

    it 'validates status is sent or failed' do
      expect(build(:notification_log, status: 'sent')).to be_valid
      expect(build(:notification_log, status: 'failed')).to be_valid
      expect(build(:notification_log, status: 'pending')).not_to be_valid
    end
  end

  describe '.recent' do
    it 'returns records ordered by created_at desc' do
      old = create(:notification_log, created_at: 2.hours.ago)
      recent = create(:notification_log, created_at: 1.minute.ago)
      expect(NotificationLog.recent.first).to eq(recent)
    end
  end
end
