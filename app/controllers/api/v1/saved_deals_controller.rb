# frozen_string_literal: true

module Api
  module V1
    class SavedDealsController < ApplicationController
      def index
        if (token = request.headers['Authorization']&.split(' ')&.last)
          begin
            payload = JwtService.decode(token)
            user = User.find_by(id: payload['user_id'])
            if user
              products = user.saved_products.order('saved_deals.created_at DESC')
              return render json: { saved_deals: products.map(&:as_json) }
            end
          rescue
            # fall through to session_id
          end
        end

        session_id = params[:session_id].to_s.strip
        if session_id.blank?
          return render json: { error: 'session_id required' }, status: :unprocessable_entity
        end

        saved = SavedDeal.where(session_id: session_id).order(created_at: :desc)
        product_ids = saved.pluck(:product_id)
        products = Product.where(id: product_ids).index_by(&:id)
        ordered = product_ids.map { |pid| products[pid] }.compact

        render json: { saved_deals: ordered.map(&:as_json) }
      end

      def create
        product_id = params[:product_id].to_i
        session_id = params[:session_id].to_s.strip

        if (token = request.headers['Authorization']&.split(' ')&.last)
          begin
            payload = JwtService.decode(token)
            user = User.find_by(id: payload['user_id'])
            if user
              product = Product.find(product_id)
              saved = user.saved_deals.find_or_initialize_by(product_id: product.id)
              saved.save!
              return render json: { saved: true, product_id: product.id }, status: :created
            end
          rescue ActiveRecord::RecordNotFound
            return render json: { error: 'Product not found' }, status: :not_found
          rescue
            # fall through to session_id
          end
        end

        if session_id.blank?
          return render json: { error: 'session_id required' }, status: :unprocessable_entity
        end

        product = Product.find(product_id)
        saved = SavedDeal.find_or_initialize_by(session_id: session_id, product_id: product.id)
        saved.save!
        render json: { saved: true, product_id: product.id }, status: :created
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Product not found' }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
      end

      def destroy
        product_id = params[:id].to_i
        session_id = params[:session_id].to_s.strip

        if (token = request.headers['Authorization']&.split(' ')&.last)
          begin
            payload = JwtService.decode(token)
            user = User.find_by(id: payload['user_id'])
            if user
              saved = user.saved_deals.find_by(product_id: product_id)
              if saved
                saved.destroy
                return render json: { saved: false, product_id: product_id }
              else
                return render json: { error: 'Not found' }, status: :not_found
              end
            end
          rescue
            # fall through to session_id
          end
        end

        if session_id.blank?
          return render json: { error: 'session_id required' }, status: :unprocessable_entity
        end

        saved = SavedDeal.find_by(session_id: session_id, product_id: product_id)
        if saved
          saved.destroy
          render json: { saved: false, product_id: product_id }
        else
          render json: { error: 'Not found' }, status: :not_found
        end
      end
    end
  end
end
