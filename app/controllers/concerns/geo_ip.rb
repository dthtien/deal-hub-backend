# frozen_string_literal: true

module GeoIp
  extend ActiveSupport::Concern

  AU_STATE_RANGES = {
    'NSW' => [
      ['1-1', '2999'],
      ['20000', '20999'],
    ],
    'ACT' => [
      ['0200', '0299'],
      ['2600', '2620'],
      ['2900', '2920'],
    ],
    'VIC' => [
      ['3000', '3999'],
      ['8000', '8999'],
    ],
    'QLD' => [
      ['4000', '4999'],
      ['9000', '9999'],
    ],
    'SA'  => [['5000', '5999']],
    'WA'  => [['6000', '6999']],
    'TAS' => [['7000', '7999']],
    'NT'  => [['0800', '0999']],
  }.freeze

  # Simple heuristic: map last octet range to an AU state for demonstration.
  # In production, replace with MaxMind GeoLite2 database lookup.
  AU_IP_HEURISTICS = {
    (1..50)   => 'NSW',
    (51..100) => 'VIC',
    (101..150) => 'QLD',
    (151..180) => 'SA',
    (181..210) => 'WA',
    (211..230) => 'TAS',
    (231..250) => 'NT',
    (251..255) => 'ACT',
  }.freeze

  included do
    before_action :detect_geo_ip
    after_action  :set_geo_ip_header
  end

  private

  def detect_geo_ip
    @detected_state = session[:detected_state] if session[:detected_state].present?
    return if @detected_state.present?

    ip = request.remote_ip.to_s
    state = detect_au_state(ip)

    if state
      @detected_state = state
      session[:detected_state] = state
    end
  end

  def set_geo_ip_header
    response.set_header('X-Detected-State', @detected_state.to_s) if @detected_state.present?
  end

  def detect_au_state(ip)
    return nil if ip.blank? || ip == '127.0.0.1' || ip.start_with?('192.168.') || ip.start_with?('10.')

    begin
      parts = ip.split('.').map(&:to_i)
      return nil unless parts.length == 4

      last_octet = parts.last
      AU_IP_HEURISTICS.each do |range, state|
        return state if range.include?(last_octet)
      end

      nil
    rescue => e
      Rails.logger.debug("GeoIp detection error: #{e.message}")
      nil
    end
  end
end
