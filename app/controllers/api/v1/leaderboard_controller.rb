module Api
  module V1
    class LeaderboardController < ApplicationController
      def show
        most_voted = Product
          .joins("LEFT JOIN votes ON votes.product_id = products.id")
          .select('products.*, COALESCE(SUM(votes.value), 0) as vote_total')
          .where(expired: false)
          .group('products.id')
          .order('vote_total DESC')
          .limit(5)

        most_clicked = Product
          .joins("LEFT JOIN click_trackings ON click_trackings.product_id = products.id")
          .select('products.*, COALESCE(COUNT(click_trackings.id), 0) as click_total')
          .where(expired: false)
          .group('products.id')
          .order('click_total DESC')
          .limit(5)

        top_stores = Product
          .select("store, AVG(discount) as avg_discount, COUNT(*) as deal_count")
          .where(expired: false)
          .where("discount IS NOT NULL AND discount > 0")
          .group(:store)
          .order('avg_discount DESC')
          .limit(5)

        biggest_discounts = Product
          .where(expired: false)
          .where("discount IS NOT NULL AND discount > 0")
          .order(discount: :desc)
          .limit(5)

        render json: {
          most_voted: most_voted.map { |p| product_json(p).merge(vote_count: p.vote_total.to_i) },
          most_clicked: most_clicked.map { |p| product_json(p).merge(click_total: p.click_total.to_i) },
          top_stores: top_stores.map { |r| { store: r.store, avg_discount: r.avg_discount.to_f.round(1), deal_count: r.deal_count } },
          biggest_discounts: biggest_discounts.map { |p| product_json(p) }
        }
      end

      private

      def product_json(p)
        { id: p.id, name: p.name, price: p.price, store: p.store, image_url: p.image_url, discount: p.discount }
      end
    end
  end
end
