# frozen_string_literal: true

module Admin
  class BaseController < ActionController::Base
    include AdminAuthentication

    layout 'admin'
  end
end
