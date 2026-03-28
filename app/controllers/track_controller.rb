# frozen_string_literal: true

class TrackController < ApplicationController
  # GET /track/open/:token
  # Token = base64 encoded "subscriber_id:notification_log_id"
  def open
    token = params[:token].to_s
    decoded = begin
      Base64.decode64(token)
    rescue
      ''
    end

    parts = decoded.split(':')
    if parts.length == 2
      notification_log_id = parts[1].to_i
      log = NotificationLog.find_by(id: notification_log_id)
      log.update_columns(opened_at: Time.current) if log && log.opened_at.nil?
    end

    # Return 1x1 transparent GIF
    gif = "\x47\x49\x46\x38\x39\x61\x01\x00\x01\x00\x80\x00\x00\xff\xff\xff" \
          "\x00\x00\x00\x21\xf9\x04\x00\x00\x00\x00\x00\x2c\x00\x00\x00\x00" \
          "\x01\x00\x01\x00\x00\x02\x02\x44\x01\x00\x3b"

    response.headers['Cache-Control'] = 'no-store, no-cache, must-revalidate, private'
    response.headers['Pragma'] = 'no-cache'
    send_data gif, type: 'image/gif', disposition: 'inline'
  end
end
