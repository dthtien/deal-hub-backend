# frozen_string_literal: true

class HealthController < ActionController::API
  def show
    db_status = begin
      ActiveRecord::Base.connection.execute('SELECT 1')
      'connected'
    rescue StandardError
      'error'
    end

    sidekiq_status = begin
      Sidekiq::ProcessSet.new.size > 0 ? 'running' : 'idle'
    rescue StandardError
      'unknown'
    end

    render json: {
      status: 'ok',
      db: db_status,
      sidekiq: sidekiq_status,
      version: '1.0.0',
      timestamp: Time.current
    }
  end
end
