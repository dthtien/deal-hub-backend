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

  # Upsert products one-by-one so we can detect price changes and record history.
  # Slower than upsert_all but correct — acceptable since crawls run infrequently.
  def upsert_with_price_history(attributes_list, store:)
    attributes_list.each do |attrs|
      # Duplicate detection: same name+store but different store_product_id
      product = Product.find_by(store_product_id: attrs[:store_product_id], store: store)
      if product.nil?
        duplicate = Product.find_by(name: attrs[:name], store: store)
        if duplicate && duplicate.store_product_id != attrs[:store_product_id].to_s
          # Update the existing record's store_product_id instead of creating a new one
          duplicate.update_column(:store_product_id, attrs[:store_product_id])
          product = duplicate
        end
      end
      product ||= Product.new(store_product_id: attrs[:store_product_id], store: store)

      new_price = attrs[:price].to_f
      old_price = attrs[:old_price].to_f
      price_changed = product.persisted? && product.price.to_f != new_price

      # Detect deal expiry: price went back up to/above old_price (discount gone)
      attrs[:expired] = old_price > 0 && new_price >= old_price

      product.assign_attributes(attrs)

      begin
        product.save!
        product.update_column(:deal_score, product.deal_score)
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
    end
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
    stale.delete_all
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
