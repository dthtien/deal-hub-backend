# frozen_string_literal: true

module Api
  module V1
    # Public endpoint — FE fetches this on load to get affiliate config
    class AffiliateConfigsController < ApplicationController
      def index
        render json: { affiliate_configs: AffiliateConfig.as_map }
      end
    end
  end
end
