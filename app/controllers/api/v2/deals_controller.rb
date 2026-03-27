# frozen_string_literal: true

module Api
  module V2
    # V2 DealsController inherits V1 but adds:
    # - include_expired: false by default (expired deals excluded)
    # - snake_case keys (already the default in this codebase)
    # This scaffolds the V2 upgrade path for future breaking changes.
    class DealsController < Api::V1::DealsController
      def index
        # V2 default: exclude expired deals (same as V1 but explicit)
        params[:include_expired] ||= 'false'
        super
      end
    end
  end
end
