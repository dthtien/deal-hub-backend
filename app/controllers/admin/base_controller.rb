# frozen_string_literal: true

module Admin
  class BaseController < ActionController::Base
    layout 'admin'
    before_action :authenticate_admin!

    private

    def authenticate_admin!
      authenticate_or_request_with_http_basic('Admin') do |username, password|
        username == ENV.fetch('ADMIN_USERNAME', 'admin') &&
          ActiveSupport::SecurityUtils.secure_compare(
            password,
            ENV.fetch('ADMIN_PASSWORD', 'changeme')
          )
      end
    end
  end
end
