# frozen_string_literal: true

class FeedController < ApplicationController
  SITE_URL = 'https://www.ozvfy.com'
  FEED_TITLE = 'OzVFY — Best Deals in Australia'
  FEED_DESC  = 'Daily curated deals from top Australian retailers — JB Hi-Fi, Myer, The Iconic, ASOS and more.'

  def index
    @products = Product.where(expired: false)
                       .order(created_at: :desc)
                       .limit(50)

    xml = String.new("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n")
    xml << "<rss version=\"2.0\" xmlns:media=\"http://search.yahoo.com/mrss/\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n"
    xml << "<channel>\n"
    xml << "  <title>#{CGI.escapeHTML(FEED_TITLE)}</title>\n"
    xml << "  <link>#{SITE_URL}</link>\n"
    xml << "  <description>#{CGI.escapeHTML(FEED_DESC)}</description>\n"
    xml << "  <language>en-au</language>\n"
    xml << "  <ttl>60</ttl>\n"
    xml << "  <atom:link href=\"#{SITE_URL}/feed.xml\" rel=\"self\" type=\"application/rss+xml\" />\n"
    xml << "  <image><url>#{SITE_URL}/logo.png</url><title>#{CGI.escapeHTML(FEED_TITLE)}</title><link>#{SITE_URL}</link></image>\n"

    @products.each do |p|
      discount_text = p.discount&.positive? ? " [#{p.discount.to_i}% OFF]" : ''
      old_price_text = p.old_price&.positive? ? " (was $#{p.old_price})" : ''
      title = "#{p.store}#{discount_text}: #{p.name.to_s.truncate(100)}"
      desc  = "$#{p.price}#{old_price_text} — #{p.description.presence || p.name}".truncate(500)

      img_url = p.image_url.presence || Array(p.image_urls).first.presence
      categories = Array(p.categories).compact.reject(&:empty?)
      category_tag = categories.first.presence || p.store

      xml << "  <item>\n"
      xml << "    <title>#{CGI.escapeHTML(title)}</title>\n"
      xml << "    <link>#{SITE_URL}/deals/#{p.id}</link>\n"
      xml << "    <guid isPermaLink=\"true\">#{SITE_URL}/deals/#{p.id}</guid>\n"
      xml << "    <description>#{CGI.escapeHTML(desc)}</description>\n"
      xml << "    <pubDate>#{p.created_at.rfc2822}</pubDate>\n"
      xml << "    <category>#{CGI.escapeHTML(category_tag)}</category>\n"
      if img_url.present?
        xml << "    <media:content url=\"#{CGI.escapeHTML(img_url)}\" medium=\"image\" />\n"
        xml << "    <enclosure url=\"#{CGI.escapeHTML(img_url)}\" type=\"image/jpeg\" length=\"0\" />\n"
      end
      xml << "  </item>\n"
    end

    xml << "</channel>\n</rss>"

    render plain: xml, content_type: 'application/rss+xml'
  end
end
