# frozen_string_literal: true

class AuthController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  FRONTEND_URL = ENV.fetch('APP_URL', 'https://www.ozvfy.com').chomp('/')

  def google_callback
    auth = request.env['omniauth.auth']

    unless auth
      return redirect_to "#{FRONTEND_URL}?auth_error=no_auth_data", allow_other_host: true
    end

    info = auth['info'] || {}
    user = User.from_google(
      'email'      => info['email'],
      'uid'        => auth['uid'],
      'first_name' => info['first_name'],
      'last_name'  => info['last_name'],
      'avatar_url' => info['image']
    )

    token = JwtService.encode({ user_id: user.id, email: user.email })
    redirect_to "#{FRONTEND_URL}?token=#{token}", allow_other_host: true
  rescue => e
    Rails.logger.error "Google OAuth error: #{e.message}"
    redirect_to "#{FRONTEND_URL}?auth_error=#{CGI.escape(e.message)}", allow_other_host: true
  end

  def me
    token = request.headers['Authorization']&.sub('Bearer ', '')
    payload = JwtService.decode(token)

    unless payload
      return render json: { error: 'Unauthorized' }, status: :unauthorized
    end

    user = User.find_by(id: payload['user_id'])
    return render json: { error: 'User not found' }, status: :not_found unless user

    render json: {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      avatar_url: user.avatar_url
    }
  end
end
