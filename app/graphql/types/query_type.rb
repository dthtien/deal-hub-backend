# frozen_string_literal: true

module Types
  class QueryType < BaseObject
    field :deals,
          [Types::ProductType],
          null: false,
          description: 'List deals with optional filters' do
      argument :limit,        Integer, required: false, default_value: 20
      argument :store,        String,  required: false
      argument :min_discount, Integer, required: false
    end

    def deals(limit:, store: nil, min_discount: nil)
      scope = Product.where(expired: false).order(deal_score: :desc, created_at: :desc)
      scope = scope.where(store: store) if store.present?
      scope = scope.where('discount >= ?', min_discount) if min_discount.present?
      scope.limit([limit, 100].min)
    end
  end
end
