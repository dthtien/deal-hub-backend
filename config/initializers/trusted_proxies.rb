# frozen_string_literal: true

require 'ipaddr'

# Proxies in front of the app that are allowed to tell us the visitor's address.
#
# Behind a CDN such as Cloudflare, the address that connects to us is the CDN's,
# and the visitor's address arrives in X-Forwarded-For. Rails and Rack only
# believe that header for proxies they trust; by default that is private
# networks only. Without this, every visitor behind the CDN looks like the CDN,
# so rate limits, the crawler rules and the logs all use the wrong address.
#
# TRUSTED_PROXY_NETWORKS is a comma separated list of CIDR ranges, for example
# Cloudflare's published ranges. It is empty by default, which changes nothing.
# The ingress must also be told to accept X-Forwarded-For only from these same
# ranges, otherwise anyone could claim to be any address.
module TrustedProxies
  NETWORKS = ENV.fetch('TRUSTED_PROXY_NETWORKS', '')
                .split(',').map(&:strip).reject(&:empty?)
                .map { |cidr| IPAddr.new(cidr) }.freeze

  def self.include?(ip)
    address = IPAddr.new(ip.to_s)
    NETWORKS.any? { |range| range.include?(address) }
  rescue IPAddr::Error
    false
  end
end

if TrustedProxies::NETWORKS.any?
  # request.remote_ip (used in the Rails log and in controllers)
  Rails.application.config.action_dispatch.trusted_proxies =
    ActionDispatch::RemoteIp::TRUSTED_PROXIES + TrustedProxies::NETWORKS

  # Rack::Request#ip (used by Rack::Attack)
  default_filter = Rack::Request.ip_filter
  Rack::Request.ip_filter = ->(ip) { default_filter.call(ip) || TrustedProxies.include?(ip) }
end
