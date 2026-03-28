# frozen_string_literal: true

module Types
  class MutationType < BaseObject
    field :track_view,
          Boolean,
          null: false,
          description: 'Track a product view. Returns true on success.' do
      argument :product_id, ID, required: true
    end

    def track_view(product_id:)
      product = Product.find_by(id: product_id)
      return false unless product

      Product.update_counters(product.id, view_count: 1)
      true
    end
  end
end
