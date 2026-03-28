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

    field :stores,
          [Types::StoreType],
          null: false,
          description: 'List stores with deal stats' do
      argument :limit, Integer, required: false, default_value: 20
    end

    def stores(limit:)
      stats = Product.where(expired: false)
                     .group(:store)
                     .select(
                       :store,
                       'COUNT(*) AS deal_count',
                       'ROUND(AVG(CASE WHEN discount > 0 THEN discount ELSE NULL END)::numeric, 1) AS avg_discount'
                     )

      stats.first(limit).map do |row|
        { name: row.store, deal_count: row.deal_count.to_i, avg_discount: row.avg_discount.to_f }
      end
    end

    field :categories,
          [Types::CategoryType],
          null: false,
          description: 'List categories with deal counts' do
      argument :limit, Integer, required: false, default_value: 20
    end

    def categories(limit:)
      rows = Product.where(expired: false).pluck(:categories).flatten.compact.reject(&:empty?)
      tally = rows.tally.sort_by { |_, v| -v }.first(limit)
      tally.map { |name, count| { name: name, count: count } }
    end

    field :trending_deals,
          [Types::ProductType],
          null: false,
          description: 'Trending deals in the last 24 hours' do
      argument :limit, Integer, required: false, default_value: 10
    end

    def trending_deals(limit:)
      since = 24.hours.ago

      click_counts  = ClickTracking.where(clicked_at: since..).group(:product_id).count
      upvote_counts = Vote.where(vote_type: 'up', created_at: since..).group(:product_id).count

      scored_ids = (click_counts.keys | upvote_counts.keys).uniq
      return [] if scored_ids.empty?

      view_counts = Product.where(id: scored_ids, expired: false).pluck(:id, :view_count).to_h

      scored = scored_ids.map do |pid|
        vc = view_counts[pid].to_f
        uc = upvote_counts[pid].to_f
        cc = click_counts[pid].to_f
        score = vc * 0.3 + uc * 0.5 + cc * 0.2
        [pid, score]
      end

      top_ids = scored.sort_by { |_, s| -s }.first(limit).map(&:first)
      Product.where(id: top_ids, expired: false)
    end
  end
end
