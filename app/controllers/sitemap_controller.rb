# frozen_string_literal: true
require 'cgi'

class SitemapController < ApplicationController
  SITE_URL = 'https://www.ozvfy.com'

  def index
    response.set_header('Cache-Control', 'public, max-age=86400')
    products   = Product.where(expired: false).select(:id, :updated_at).order(updated_at: :desc).limit(100)
    stores     = Product.distinct.pluck(:store).compact.sort
    categories = Product.where("array_length(categories, 1) > 0")
                        .pluck(:categories).flatten.tally
                        .sort_by { |_, c| -c }.first(50).map(&:first)
    searches   = SearchQuery.trending(limit: 50).pluck(:query)

    xml = String.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    xml << "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"

    # Static pages
    [
      ['/', 'hourly', '1.0'],
      ['/subscribe', 'monthly', '0.5'],
      ['/deals/new', 'hourly', '0.9'],
      ['/best-drops', 'hourly', '0.9'],
      ['/deals/expiring', 'hourly', '0.9'],
      ['/deals/bundles', 'daily', '0.8'],
      ['/feed.xml', 'hourly', '0.8'],
      ['/sales-calendar', 'weekly', '0.7'],
      ['/coupons', 'weekly', '0.7'],
      ['/about', 'monthly', '0.6'],
      ['/privacy-policy', 'monthly', '0.4'],
    ].each do |path, freq, pri|
      xml << "  <url><loc>#{SITE_URL}#{path}</loc><changefreq>#{freq}</changefreq><priority>#{pri}</priority></url>\n"
    end

    stores.each do |store|
      xml << "  <url><loc>#{SITE_URL}/stores/#{CGI.escape(store)}</loc><changefreq>daily</changefreq><priority>0.7</priority></url>\n"
    end

    categories.each do |cat|
      xml << "  <url><loc>#{SITE_URL}/categories/#{CGI.escape(cat)}</loc><changefreq>daily</changefreq><priority>0.6</priority></url>\n"
    end

    searches.each do |q|
      xml << "  <url><loc>#{SITE_URL}/deals/search/#{CGI.escape(q.downcase)}</loc><changefreq>daily</changefreq><priority>0.5</priority></url>\n"
    end

    products.each do |product|
      xml << "  <url><loc>#{SITE_URL}/deals/#{product.id}</loc><lastmod>#{product.updated_at.strftime('%Y-%m-%d')}</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>\n"
    end

    xml << "</urlset>"

    render plain: xml, content_type: 'application/xml'
  rescue => e
    Rails.logger.error("SitemapController#index error: #{e.message}")
    render plain: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"></urlset>", content_type: 'application/xml'
  end

  def sitemap_index
    xml = String.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    xml << "<sitemapindex xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
    [
      '/sitemap.xml',
      '/sitemap_deals.xml',
      '/sitemap_stores.xml',
      '/sitemap_brands.xml',
      '/sitemap_collections.xml',
      '/sitemap_categories.xml'
    ].each do |loc|
      xml << "  <sitemap><loc>#{SITE_URL}#{loc}</loc></sitemap>\n"
    end
    xml << "</sitemapindex>"
    render plain: xml, content_type: 'application/xml'
  end

  def sitemap_brands
    brands = Product.where.not(brand: [nil, ''])
                    .group(:brand)
                    .order(Arel.sql('COUNT(*) DESC'))
                    .limit(100)
                    .pluck(:brand)

    xml = String.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    xml << "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
    brands.each do |brand|
      xml << "  <url><loc>#{SITE_URL}/brands/#{CGI.escape(brand)}</loc><changefreq>daily</changefreq><priority>0.7</priority></url>\n"
    end
    xml << "</urlset>"
    render plain: xml, content_type: 'application/xml'
  rescue => e
    Rails.logger.error("SitemapController#sitemap_brands error: #{e.message}")
    render plain: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"></urlset>", content_type: 'application/xml'
  end

  def sitemap_collections
    collections = Collection.where(active: true).select(:slug, :updated_at)

    xml = String.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    xml << "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
    collections.each do |col|
      lastmod = col.updated_at&.strftime('%Y-%m-%d') || Date.today.to_s
      xml << "  <url><loc>#{SITE_URL}/collections/#{CGI.escape(col.slug)}</loc><lastmod>#{lastmod}</lastmod><changefreq>weekly</changefreq><priority>0.6</priority></url>\n"
    end
    xml << "</urlset>"
    render plain: xml, content_type: 'application/xml'
  rescue => e
    Rails.logger.error("SitemapController#sitemap_collections error: #{e.message}")
    render plain: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"></urlset>", content_type: 'application/xml'
  end

  def sitemap_categories
    categories = Product.where("array_length(categories, 1) > 0")
                        .pluck(:categories).flatten.tally
                        .sort_by { |_, c| -c }.map(&:first)

    xml = String.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    xml << "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
    categories.each do |cat|
      xml << "  <url><loc>#{SITE_URL}/categories/#{CGI.escape(cat)}</loc><changefreq>daily</changefreq><priority>0.6</priority></url>\n"
    end
    xml << "</urlset>"
    render plain: xml, content_type: 'application/xml'
  rescue => e
    Rails.logger.error("SitemapController#sitemap_categories error: #{e.message}")
    render plain: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"></urlset>", content_type: 'application/xml'
  end

  def sitemap_deals
    products = Product.where(expired: false).select(:id, :updated_at).order(updated_at: :desc).limit(1000)
    xml = String.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    xml << "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"
    products.each do |product|
      xml << "  <url><loc>#{SITE_URL}/deals/#{product.id}</loc><lastmod>#{product.updated_at.strftime('%Y-%m-%d')}</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>\n"
    end
    xml << "</urlset>"
    render plain: xml, content_type: 'application/xml'
  rescue => e
    Rails.logger.error("SitemapController#sitemap_deals error: #{e.message}")
    render plain: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"></urlset>", content_type: 'application/xml'
  end

  def sitemap_stores
    stores     = Product.distinct.pluck(:store).compact.sort
    categories = Product.where("array_length(categories, 1) > 0")
                        .pluck(:categories).flatten.tally
                        .sort_by { |_, c| -c }.first(100).map(&:first)
    searches   = SearchQuery.trending(limit: 100).pluck(:query)

    xml = String.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    xml << "<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\">\n"

    # Get lastmod per store (max updated_at of its products)
    store_lastmod = Product.where(store: stores)
                           .group(:store)
                           .maximum(:updated_at)

    stores.each do |store|
      lastmod = store_lastmod[store]&.strftime('%Y-%m-%d') || Date.today.to_s
      xml << "  <url><loc>#{SITE_URL}/stores/#{CGI.escape(store)}</loc><lastmod>#{lastmod}</lastmod><changefreq>daily</changefreq><priority>0.8</priority></url>\n"
    end
    categories.each do |cat|
      xml << "  <url><loc>#{SITE_URL}/categories/#{CGI.escape(cat)}</loc><changefreq>daily</changefreq><priority>0.6</priority></url>\n"
    end
    searches.each do |q|
      xml << "  <url><loc>#{SITE_URL}/deals/search/#{CGI.escape(q.downcase)}</loc><changefreq>daily</changefreq><priority>0.5</priority></url>\n"
    end

    xml << "</urlset>"
    render plain: xml, content_type: 'application/xml'
  rescue => e
    Rails.logger.error("SitemapController#sitemap_stores error: #{e.message}")
    render plain: "<?xml version=\"1.0\" encoding=\"UTF-8\"?><urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"></urlset>", content_type: 'application/xml'
  end
end
