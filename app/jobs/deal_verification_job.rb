# frozen_string_literal: true

class DealVerificationJob < ApplicationJob
  queue_as :default

  SHOPIFY_STORES = [
    'Glue Store',
    'Culture Kings',
    'Beginning Boutique',
    'Universal Store',
    'Lorna Jane',
    'Good Buyz'
  ].freeze

  PRICE_TOLERANCE = 0.10 # 10%

  def perform(product_id = nil)
    scope = product_id ? Product.where(id: product_id) : Product.where(store: SHOPIFY_STORES, expired: false)

    scope.find_each do |product|
      verify_product(product)
    end
  end

  private

  def verify_product(product)
    return unless shopify_store?(product.store)

    fetched_price = fetch_shopify_price(product)
    return if fetched_price.nil?

    stored_price = product.price.to_f
    diff = (fetched_price - stored_price).abs / [stored_price, 0.01].max

    if diff > PRICE_TOLERANCE
      product.update_columns(price_verified: false, verified_at: Time.current)
      Rails.logger.info "[DealVerificationJob] Price mismatch for product #{product.id}: stored=#{stored_price} fetched=#{fetched_price}"
    else
      product.update_columns(price_verified: true, verified_at: Time.current)
    end
  rescue StandardError => e
    Rails.logger.error "[DealVerificationJob] Error verifying product #{product.id}: #{e.message}"
  end

  def shopify_store?(store)
    SHOPIFY_STORES.include?(store)
  end

  def fetch_shopify_price(product)
    return nil if product.store_path.blank?

    store_domain = shopify_domain_for(product.store)
    return nil if store_domain.nil?

    # Shopify product JSON endpoint: /products/<handle>.json
    handle = product.store_path.to_s.split('/').last.split('?').first
    return nil if handle.blank?

    url = "https://#{store_domain}/products/#{handle}.json"
    response = Net::HTTP.get_response(URI.parse(url))
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    variants = data.dig('product', 'variants')
    return nil if variants.nil? || variants.empty?

    variants.first['price'].to_f
  rescue StandardError
    nil
  end

  def shopify_domain_for(store)
    {
      'Glue Store'          => 'www.gluestore.com.au',
      'Culture Kings'       => 'www.culturekings.com.au',
      'Beginning Boutique'  => 'www.beginningboutique.com.au',
      'Universal Store'     => 'www.universalstore.com.au',
      'Lorna Jane'          => 'www.lornajane.com.au',
      'Good Buyz'           => 'www.goodbuyz.com.au'
    }[store]
  end
end
