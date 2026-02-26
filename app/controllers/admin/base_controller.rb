# frozen_string_literal: true

module Admin
  class BaseController < ApplicationController
    before_action :authenticate!

    private

    def authenticate!
      authenticate_or_request_with_http_basic('Admin') do |username, password|
        username == ENV.fetch('ADMIN_USERNAME', 'admin') &&
          password == ENV.fetch('ADMIN_PASSWORD', 'changeme')
      end
    end
  end
end
