# frozen_string_literal: true

module RequestLogger
  extend ActiveSupport::Concern

  included do
    around_action :log_request
  end

  private

  def log_request
    return yield if request.path == '/health'

    start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round

    ip = request.remote_ip
    log_line = "[API] #{request.method} #{request.path} - #{response.status} - #{duration_ms}ms - #{ip}"

    if duration_ms > 500
      Rails.logger.warn("SLOW REQUEST #{log_line}")
    else
      Rails.logger.info(log_line)
    end
  end
end
