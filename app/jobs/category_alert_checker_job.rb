# frozen_string_literal: true

class CategoryAlertCheckerJob < ApplicationJob
  queue_as :default

  CATEGORY_KEYWORDS = {
    "Women's Fashion"    => %w[women dress skirt bra ladies womenswear],
    "Men's Fashion"      => %w[men polo suit mens menswear],
    'Activewear'         => %w[active sport gym yoga running activewear],
    'Shoes & Footwear'   => %w[shoe sneaker boot sandal footwear],
    'Electronics'        => %w[electronic laptop phone audio tv gaming camera],
    'Home & Living'      => %w[home furniture kitchen bedding bath],
    'Beauty & Health'    => %w[beauty health skin fragrance vitamin],
    'Bags & Accessories' => %w[bag accessory accessories watch jewel],
    'Outdoor & Sports'   => %w[outdoor camp hike bike swim fishing],
    'Kids & Toys'        => %w[kid toy baby child junior]
  }.freeze

  def perform
    since = 1.hour.ago

    CategoryAlert.where(active: true).group_by(&:category).each do |category, alerts|
      keywords = CATEGORY_KEYWORDS[category]
      next unless keywords

      new_products = find_new_products_for_category(keywords, since)
      next if new_products.empty?

      alerts.each do |alert|
        begin
          send_alert(alert, new_products)
        rescue StandardError => e
          Rails.logger.error("[CategoryAlertCheckerJob] Error for #{alert.email}: #{e.message}")
        end
      end
    end
  end

  private

  def find_new_products_for_category(keywords, since)
    keywords.flat_map do |kw|
      Product.where('categories::text ILIKE ?', "%#{kw}%")
             .where(expired: false)
             .where('created_at >= ?', since)
             .limit(5)
    end.uniq(&:id).first(10)
  end

  def send_alert(alert, products)
    subject_line = "New #{alert.category} deals on OzVFY!"
    site_url     = ENV.fetch('SITE_URL', 'https://www.ozvfy.com')

    mail = ApplicationMailer.mail(
      to:      alert.email,
      from:    ENV.fetch('MAILER_FROM', 'deals@ozvfy.com'),
      subject: subject_line
    ) do |format|
      format.html do
        render inline: <<~HTML, locals: { products: products, category: alert.category, site_url: site_url }
          <h2>New <%= category %> deals just dropped!</h2>
          <% products.each do |p| %>
            <p><strong><%= p.name %></strong> - $<%= p.price %></p>
          <% end %>
          <p><a href="<%= site_url %>">View all deals</a></p>
        HTML
      end
    end

    begin
      mail.deliver_now
      NotificationLog.create!(
        notification_type: 'category_alert',
        recipient:         alert.email,
        subject:           subject_line,
        status:            'sent'
      )
    rescue StandardError => e
      NotificationLog.create!(
        notification_type: 'category_alert',
        recipient:         alert.email,
        subject:           subject_line,
        status:            'failed'
      )
      raise e
    end
  end
end
