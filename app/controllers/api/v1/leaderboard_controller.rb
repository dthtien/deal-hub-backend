module Api
  module V1
    class LeaderboardController < ApplicationController
      def show
        most_voted = Product
          .joins(:votes)
          .select('products.*, SUM(votes.value) as vote_total')
          .group('products.id')
          .order('vote_total DESC')
          .limit(5)

        most_clicked = Product
          .joins(:click_trackings)
          .select('products.*, COUNT(click_trackings.id) as click_total')
          .group('products.id')
          .order('click_total DESC')
          .limit(5)

        top_stores = Product
          .select("store, AVG(discount) as avg_discount, COUNT(*) as deal_count")
          .where("discount IS NOT NULL AND discount > 0")
          .group(:store)
          .order('avg_discount DESC')
          .limit(5)

        biggest_discounts = Product
          .where("discount IS NOT NULL AND discount > 0")
          .order(discount: :desc)
          .limit(5)

        render json: {
          most_voted: most_voted.map { |p| product_json(p).merge(vote_count: p.respond_to?(:vote_total) ? p.vote_total.to_i : 0) },
          most_clicked: most_clicked.map { |p| product_json(p).merge(click_total: p.respond_to?(:click_total) ? p.click_total.to_i : 0) },
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
