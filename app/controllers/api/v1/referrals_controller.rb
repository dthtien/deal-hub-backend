# frozen_string_literal: true

module Api
  module V1
    class ReferralsController < ApplicationController
      def link
        session_id = params[:session_id].to_s.strip
        if session_id.blank?
          return render json: { error: 'session_id required' }, status: :unprocessable_entity
        end

        referral = Referral.find_or_create_for_session(session_id)
        render json: {
          code: referral.code,
          url: "#{request.base_url}/r/#{referral.code}",
          click_count: referral.click_count,
          conversion_count: referral.conversion_count,
          estimated_reward: referral.estimated_reward
        }
      end

      def stats
        session_id = params[:session_id].to_s.strip
        if session_id.blank?
          return render json: { error: 'session_id required' }, status: :unprocessable_entity
        end

        referral = Referral.find_or_create_for_session(session_id)
        render json: {
          code: referral.code,
          click_count: referral.click_count,
          conversion_count: referral.conversion_count,
          estimated_reward: referral.estimated_reward
        }
      end
    end
  end
end
