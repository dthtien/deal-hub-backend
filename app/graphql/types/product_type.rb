# frozen_string_literal: true

module Types
  class ProductType < BaseObject
    field :id,         Integer, null: false
    field :name,       String,  null: true
    field :price,      Float,   null: true
    field :discount,   Float,   null: true
    field :store,      String,  null: true
    field :image_url,  String,  null: true
    field :deal_score, Integer, null: true

    def deal_score
      object.deal_score
    end
  end
end
