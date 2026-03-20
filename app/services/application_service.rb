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

  # Safe product removal — deletes click_trackings first to avoid FK violations.
  # Use this instead of .delete_all in all crawl services.
  def remove_products_for_store(store:, keep_store_product_ids:)
    stale = Product.where(store:).where.not(store_product_id: keep_store_product_ids)
    # Delete associated click_trackings first (delete_all bypasses dependent: :destroy)
    ClickTracking.where(product_id: stale.select(:id)).delete_all
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
