# frozen_string_literal: true

class FeedController < ApplicationController
  SITE_URL = 'https://www.ozvfy.com'
  FEED_TITLE = 'OzVFY — Best Deals in Australia'
  FEED_DESC  = 'Daily curated deals from top Australian retailers — JB Hi-Fi, Myer, The Iconic, ASOS and more.'

  def store
    store_name = CGI.unescape(params[:name].to_s)
    @products = Product.where(expired: false, store: store_name)
                       .order(created_at: :desc)
                       .limit(20)

    feed_title = "OzVFY #{store_name} Deals"
    feed_desc  = "Top deals from #{store_name} on OzVFY."
    feed_url   = "#{SITE_URL}/stores/#{params[:name]}/feed.xml"
    store_page = "#{SITE_URL}/stores/#{CGI.escape(store_name)}"

    render plain: build_rss(feed_title, feed_desc, feed_url, store_page, @products),
           content_type: 'application/rss+xml'
  end

  def index
    @products = Product.where(expired: false)
                       .order(created_at: :desc)
                       .limit(50)

    render plain: build_rss(FEED_TITLE, FEED_DESC, "#{SITE_URL}/feed.xml", SITE_URL, @products),
           content_type: 'application/rss+xml'
  end

  private

  def build_rss(title, desc, self_url, link_url, products)
    xml = String.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    xml << "<rss version=\"2.0\" xmlns:media=\"http://search.yahoo.com/mrss/\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n"
    xml << "<channel>\n"
    xml << "  <title>#{CGI.escapeHTML(title)}</title>\n"
    xml << "  <link>#{link_url}</link>\n"
    xml << "  <description>#{CGI.escapeHTML(desc)}</description>\n"
    xml << "  <language>en-au</language>\n"
    xml << "  <ttl>60</ttl>\n"
    xml << "  <atom:link href=\"#{self_url}\" rel=\"self\" type=\"application/rss+xml\" />\n"
    xml << "  <image><url>#{SITE_URL}/logo.png</url><title>#{CGI.escapeHTML(title)}</title><link>#{link_url}</link></image>\n"

    products.each do |p|
      discount_text = p.discount&.positive? ? " [#{p.discount.to_i}% OFF]" : ''
      old_price_text = p.old_price&.positive? ? " (was $#{p.old_price})" : ''
      item_title = "#{p.store}#{discount_text}: #{p.name.to_s.truncate(100)}"
      item_desc  = "$#{p.price}#{old_price_text} -- #{p.description.presence || p.name}".truncate(500)

      img_url = p.image_url.presence || Array(p.image_urls).first.presence
      categories = Array(p.categories).compact.reject(&:empty?)
      category_tag = categories.first.presence || p.store

      xml << "  <item>\n"
      xml << "    <title>#{CGI.escapeHTML(item_title)}</title>\n"
      xml << "    <link>#{SITE_URL}/deals/#{p.id}</link>\n"
      xml << "    <guid isPermaLink=\"true\">#{SITE_URL}/deals/#{p.id}</guid>\n"
      xml << "    <description>#{CGI.escapeHTML(item_desc)}</description>\n"
      xml << "    <pubDate>#{p.created_at.rfc2822}</pubDate>\n"
      xml << "    <category>#{CGI.escapeHTML(category_tag)}</category>\n"
      if img_url.present?
        xml << "    <media:content url=\"#{CGI.escapeHTML(img_url)}\" medium=\"image\" />\n"
        xml << "    <enclosure url=\"#{CGI.escapeHTML(img_url)}\" type=\"image/jpeg\" length=\"0\" />\n"
      end
      xml << "  </item>\n"
    end

    xml << "</channel>\n</rss>"
    xml
  end
end
