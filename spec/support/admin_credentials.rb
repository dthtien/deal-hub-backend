# frozen_string_literal: true

# Sets the admin login for one example and restores the environment afterwards.
#
#   with_admin_credentials('admin', 's3cret') { ... }
module AdminCredentialsHelper
  def with_admin_credentials(username, password)
    saved = ENV.to_h.slice('ADMIN_USERNAME', 'ADMIN_PASSWORD')
    username.nil? ? ENV.delete('ADMIN_USERNAME') : ENV['ADMIN_USERNAME'] = username
    password.nil? ? ENV.delete('ADMIN_PASSWORD') : ENV['ADMIN_PASSWORD'] = password
    yield
  ensure
    %w[ADMIN_USERNAME ADMIN_PASSWORD].each { |key| saved.key?(key) ? ENV[key] = saved[key] : ENV.delete(key) }
  end

  def admin_auth_header(username, password)
    { 'Authorization' => ActionController::HttpAuthentication::Basic.encode_credentials(username, password) }
  end
end

RSpec.configure do |config|
  config.include AdminCredentialsHelper
end
