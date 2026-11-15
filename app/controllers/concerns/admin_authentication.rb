# frozen_string_literal: true

# HTTP Basic login for the admin area and the admin API.
#
# The username and password come from ADMIN_USERNAME and ADMIN_PASSWORD. There
# are no built-in defaults: if either is missing or empty, every login is
# refused. A default such as admin/changeme, or an empty value, would leave the
# admin area open to anyone who guessed it.
module AdminAuthentication
  extend ActiveSupport::Concern

  # ActionController::API does not include Basic auth on its own
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  included do
    before_action :authenticate_admin!
  end

  def self.configured?
    ENV['ADMIN_USERNAME'].present? && ENV['ADMIN_PASSWORD'].present?
  end

  def self.valid?(username, password)
    return false unless configured?

    # Compare both values in full so a wrong guess takes the same time either way
    user_ok = ActiveSupport::SecurityUtils.secure_compare(username.to_s, ENV['ADMIN_USERNAME'])
    pass_ok = ActiveSupport::SecurityUtils.secure_compare(password.to_s, ENV['ADMIN_PASSWORD'])
    user_ok && pass_ok
  end

  private

  def authenticate_admin!
    unless AdminAuthentication.configured?
      Rails.logger.warn('Admin login refused: ADMIN_USERNAME and ADMIN_PASSWORD must both be set')
    end

    authenticate_or_request_with_http_basic('Admin') do |username, password|
      AdminAuthentication.valid?(username, password)
    end
  end
end
