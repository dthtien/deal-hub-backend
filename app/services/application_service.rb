class ApplicationService
  def self.call(*args, &block)
    new(*args, &block).call
  end

  def call
    raise NotImplementedError, "Please implement #{self.class}#call"
  end

  private

  def calculate_discount(old_price, price)
    return if old_price.zero? || price.zero?

    ((old_price.to_f - price.to_f) / old_price.to_f * 100).round
  end
end
