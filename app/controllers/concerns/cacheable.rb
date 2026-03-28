# frozen_string_literal: true

module Cacheable
  extend ActiveSupport::Concern

  included do
    after_action :set_vary_header
  end

  private

  def set_vary_header
    response.headers['Vary'] = 'Accept-Encoding'
  end

  # Build a cache key incorporating common query params + user segment
  def cache_key_for(base, extra: {})
    segment = current_user_segment
    parts = {
      base: base,
      page: params[:page],
      per_page: params[:per_page],
      sort: params[:sort] || params[:sort_by],
      sort_dir: params[:sort_dir] || params[:order],
      segment: segment
    }.merge(extra)
    parts.compact.map { |k, v| "#{k}:#{v}" }.sort.join('/')
  end

  # Stale-while-revalidate: return cached data immediately, refresh in background
  def swr_fetch(key, expires_in: 5.minutes, stale_ttl: 1.minute)
    cached = Rails.cache.read(key)

    if cached
      stale_key = "#{key}:refreshing"
      unless Rails.cache.exist?(stale_key)
        Rails.cache.write(stale_key, true, expires_in: stale_ttl)
        CacheRefreshJob.perform_later(key, expires_in.to_i) if defined?(CacheRefreshJob)
      end
      return cached
    end

    fresh = yield
    Rails.cache.write(key, fresh, expires_in: expires_in)
    fresh
  end

  def current_user_segment
    return 'guest' unless respond_to?(:current_user, true) && current_user
    current_user.try(:segment) || 'user'
  end
end
