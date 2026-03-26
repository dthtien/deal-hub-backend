# frozen_string_literal: true
require 'cgi'

class SitemapController < ApplicationController
  SITE_URL = 'https://www.ozvfy.com'

  def index
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
  end
end
