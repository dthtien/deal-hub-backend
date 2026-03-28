class ApplicationService
  attr_reader :errors
  def self.call(*args, &block)
    new(*args, &block).call
  end

  def initialize(*_args)
    @errors = []
  end

  def call
    raise NotImplementedError, "Please implement #{self.class}#call"
  end

  private

  # HTTP request with retry logic for network errors.
  # Max 3 retries, 2s sleep between attempts.
  # Only retries on network/timeout errors.
  def http_get_with_retry(url, headers: {}, max_retries: 3, sleep_secs: 2)
    retries = 0
    begin
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == 'https'
      http.open_timeout = 10
      http.read_timeout = 30
      request = Net::HTTP::Get.new(uri.request_uri, headers)
      http.request(request)
    rescue Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
      retries += 1
      if retries <= max_retries
        Rails.logger.warn "http_get_with_retry - attempt #{retries}/#{max_retries} failed for #{url}: #{e.class} #{e.message}"
        sleep sleep_secs
        retry
      else
        Rails.logger.error "http_get_with_retry - all #{max_retries} retries exhausted for #{url}: #{e.message}"
        raise
      end
    end
  end

  # Track crawl metrics — call wrap_with_crawl_log(store:) { ... } in crawl services
  def wrap_with_crawl_log(store:)
    start_time = Time.current
    @crawl_products_found   = 0
    @crawl_products_new     = 0
    @crawl_products_updated = 0
    yield
  ensure
    duration = Time.current - start_time
    begin
      found = @crawl_products_found.to_i
      new_count = @crawl_products_new.to_i
      yield_rate = found > 0 ? (new_count.to_f / found).round(4) : 0.0
      CrawlLog.create!(
        store:             store,
        products_found:    found,
        products_new:      new_count,
        products_updated:  @crawl_products_updated.to_i,
        duration_seconds:  duration.round(2),
        crawled_at:        Time.current,
        yield_rate:        yield_rate
      )
    rescue => e
      Rails.logger.error "wrap_with_crawl_log - failed to save CrawlLog: #{e.message}"
    end
  end

  # Upsert products one-by-one so we can detect price changes and record history.
  # Slower than upsert_all but correct - acceptable since crawls run infrequently.
  def upsert_with_price_history(attributes_list, store:)
    skipped_image_count = 0
    @crawl_products_found = attributes_list.size

    attributes_list.each do |attrs|
      # Image URL validation & fix (Feature 5)
      image = attrs[:image_url].to_s
      if image.start_with?('//')
        image = "https:#{image}"
        attrs[:image_url] = image
      end
      if image.present? && !image.start_with?('http')
        skipped_image_count += 1
        Rails.logger.info "upsert_with_price_history - skipping product with invalid image_url: #{attrs[:store_product_id]}"
        next
      end

      # Image scraping fallback: if image_url is blank, try to reuse from existing product
      if attrs[:image_url].blank?
        existing_with_image = Product.where(name: attrs[:name], store: store)
                                     .where.not(image_url: [nil, ''])
                                     .first
        if existing_with_image
          attrs[:image_url] = existing_with_image.image_url
          Rails.logger.info "Reused image from existing product for: #{attrs[:name]}"
        end
      end

      # Duplicate detection: find by store_product_id first, then fall back to ILIKE name match
      product = Product.find_by(store_product_id: attrs[:store_product_id], store: store)
      if product.nil?
        # Case-insensitive name + store match to prevent duplicates when SKU changes
        duplicate = Product.where(store: store)
                           .where('name ILIKE ?', attrs[:name].to_s.strip)
                           .first
        if duplicate
          # Migrate to new SKU and reuse the existing record
          duplicate.update_column(:store_product_id, attrs[:store_product_id]) if duplicate.store_product_id != attrs[:store_product_id].to_s
          product = duplicate
        end
      end
      is_new = product.nil?
      product ||= Product.new(store_product_id: attrs[:store_product_id], store: store)

      new_price = attrs[:price].to_f
      old_price = attrs[:old_price].to_f
      price_changed = product.persisted? && product.price.to_f != new_price

      # Detect deal expiry: price went back up to/above old_price (discount gone)
      attrs[:expired] = old_price > 0 && new_price >= old_price

      # Bundle detection v2: scan product name for bundle keywords and quantity
      bundle_keywords = /\b(pack|set|bundle|kit|combo|twin|duo|trio)\b/i
      attrs[:is_bundle] = attrs[:name].to_s.match?(bundle_keywords)

      # Detect bundle quantity and compute price_per_unit
      product_name = attrs[:name].to_s
      qty = if product_name =~ /\b(\d+)\s*for\s*\$?\d/i
        $1.to_i
      elsif product_name =~ /buy\s*(\d+)\s*get/i
        $1.to_i + 1
      elsif product_name =~ /\btwin\s*pack\b/i
        2
      elsif product_name =~ /\b(\d+)\s*[\-\s]?pack\b/i
        $1.to_i
      elsif product_name =~ /\bpack\s+of\s+(\d+)\b/i
        $1.to_i
      else
        1
      end
      qty = [qty, 1].max
      attrs[:bundle_quantity] = qty
      attrs[:is_bundle] = true if qty > 1
      attrs[:price_per_unit] = qty > 1 ? (attrs[:price].to_f / qty).round(2) : nil

      # Auto-generate tags from name + categories (Feature 5 - deal tagging automation)
      existing_tags = Array(attrs[:tags])
      auto_tags = TagExtractor.extract(name: attrs[:name].to_s, categories: attrs[:categories])
      attrs[:tags] = (existing_tags + auto_tags).uniq.first(10)

      product.assign_attributes(attrs)

      begin
        product.save!
        product.update_column(:deal_score, product.deal_score)
        if is_new
          @crawl_products_new = (@crawl_products_new || 0) + 1
        elsif price_changed
          @crawl_products_updated = (@crawl_products_updated || 0) + 1
        end
      rescue => e
        Rails.logger.error "upsert_with_price_history — product save failed for #{attrs[:store_product_id]}: #{e.message}"
        next
      end

      # Record on first save OR whenever price changes
      if !product.price_histories.exists? || price_changed
        product.price_histories.create!(
          price: new_price,
          old_price: attrs[:old_price],
          discount: attrs[:discount],
          recorded_at: Time.current
        )
      end

      # Fire webhook notification for new deals with high discount
      if is_new && product.discount.to_f > 40
        NotificationWebhookJob.perform_later(product.id)
      end

      # Freshness webhooks: deal.new and deal.price_drop
      if is_new
        WebhookDispatcher.dispatch('deal.new', {
          event:       'deal.new',
          product_id:  product.id,
          name:        product.name,
          store:       product.store,
          price:       product.price.to_f,
          discount:    product.discount.to_f,
          url:         product.store_url,
          occurred_at: Time.current.iso8601
        })
      elsif price_changed
        old_p = product.price_histories.order(recorded_at: :desc).second&.price.to_f
        if old_p > 0 && new_price < old_p
          drop_pct = ((old_p - new_price) / old_p * 100).round(1)
          if drop_pct > 5
            WebhookDispatcher.dispatch('deal.price_drop', {
              event:       'deal.price_drop',
              product_id:  product.id,
              name:        product.name,
              store:       product.store,
              old_price:   old_p,
              new_price:   new_price,
              drop_pct:    drop_pct,
              url:         product.store_url,
              occurred_at: Time.current.iso8601
            })
          end
        end
      end

      # Bust stores index cache when a new product is crawled
      if is_new || price_changed
        Rails.cache.delete('stores_index_v2')
      end
    end
    Rails.logger.info "upsert_with_price_history — #{store}: #{attributes_list.size} found, #{@crawl_products_new} new, #{@crawl_products_updated} updated, #{skipped_image_count} skipped (invalid image)" if skipped_image_count > 0
  end

  # Safe product removal — deletes click_trackings first to avoid FK violations.
  # Use this instead of .delete_all in all crawl services.
  def remove_products_for_store(store:, keep_store_product_ids:)
    stale = Product.where(store:).where.not(store_product_id: keep_store_product_ids)
    stale_ids = stale.select(:id)
    # delete_all bypasses dependent: :destroy — must manually delete all associations
    ClickTracking.where(product_id: stale_ids).delete_all
    Vote.where(product_id: stale_ids).delete_all
    Comment.where(product_id: stale_ids).delete_all
    PriceHistory.where(product_id: stale_ids).delete_all
    PriceAlert.where(product_id: stale_ids).delete_all
    AiDealAnalysis.where(product_id: stale_ids).delete_all
    DealRating.where(product_id: stale_ids).delete_all
    CollectionItem.where(product_id: stale_ids).delete_all
    DealReport.where(product_id: stale_ids).delete_all if defined?(DealReport)
    SavedDeal.where(product_id: stale_ids).delete_all if defined?(SavedDeal)
    DealOfDayHistory.where(product_id: stale_ids).delete_all if defined?(DealOfDayHistory)
    stale.delete_all
  end

  # Returns false if ALL variants have available: false, true otherwise
  def in_stock_from_variants(variants)
    return true if variants.blank?
    variants.any? { |v| v['available'] != false }
  end

  def calculate_discount(old_price, price)
    return 0 if old_price.zero? || price.zero?

    ((old_price.to_f - price.to_f) / old_price.to_f * 100).round
  end

  def refine_description(description, categories)
    return if categories.blank?

    category_text = categories.map { |category| "##{category}" }.join(', ')
    return category_text if description.blank?

    "#{description} \n #{categories.map { |category| "##{category}" }.join(', ')}"
  end
end
