# frozen_string_literal: true

module Api
  module V1
    class StoreFollowsController < ApplicationController
      def index
        session_id = params[:session_id].to_s
        return render json: { stores: [] } if session_id.blank?

        stores = StoreFollow.where(session_id: session_id).pluck(:store_name)
        render json: { stores: stores }
      end

      def create
        session_id = params[:session_id].to_s
        store_name = params[:store_name].to_s
        return render json: { error: 'session_id and store_name required' }, status: :unprocessable_entity if session_id.blank? || store_name.blank?

        follow = StoreFollow.find_or_create_by!(session_id: session_id, store_name: store_name)
        render json: { followed: true, store_name: follow.store_name }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      def destroy
        session_id = params[:session_id].to_s
        store_name = params[:store_name].to_s
        StoreFollow.where(session_id: session_id, store_name: store_name).delete_all
        render json: { unfollowed: true }
      end

      def deals
        session_id = params[:session_id].to_s
        return render json: { products: [], metadata: {} } if session_id.blank?

        store_names = StoreFollow.where(session_id: session_id).pluck(:store_name)
        return render json: { products: [], metadata: { total_count: 0 } } if store_names.empty?

        page     = (params[:page] || 1).to_i
        per_page = 20
        offset   = (page - 1) * per_page

        base  = Product.where(store: store_names, expired: false).order(deal_score: :desc, updated_at: :desc)
        total = base.count
        products = base.limit(per_page).offset(offset)

        render json: {
          products: products.map(&:as_json),
          metadata: {
            page: page,
            per_page: per_page,
            total_count: total,
            total_pages: (total.to_f / per_page).ceil,
            show_next_page: offset + per_page < total
          }
        }
      end
    end
  end
end
