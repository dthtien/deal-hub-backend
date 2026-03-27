# frozen_string_literal: true

module Api
  module V1
    class CategoryAlertsController < ApplicationController
      def create
        email    = params[:email].to_s.strip
        category = params[:category].to_s.strip

        if email.blank? || category.blank?
          return render json: { error: 'email and category are required' }, status: :unprocessable_entity
        end

        alert = CategoryAlert.find_or_initialize_by(email: email, category: category)
        alert.active = true

        if alert.save
          render json: { message: 'Subscribed successfully', alert: { email: alert.email, category: alert.category } }, status: :created
        else
          render json: { error: alert.errors.full_messages.join(', ') }, status: :unprocessable_entity
        end
      end

      def destroy
        email    = params[:email].to_s.strip
        category = params[:category].to_s.strip

        alert = CategoryAlert.find_by(email: email, category: category)
        if alert
          alert.update!(active: false)
          render json: { message: 'Unsubscribed successfully' }
        else
          render json: { error: 'Subscription not found' }, status: :not_found
        end
      end
    end
  end
end
