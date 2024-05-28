require 'exception_notification/rails'
require 'exception_notification/sidekiq'

ExceptionNotification.configure do |config|
  config.ignore_if do |_exception, _options|
    !Rails.env.production?
  end

  config.add_notifier :slack, {
    webhook_url: ENV['SLACK_WEBHOOK_URL'],
    channel: '#first',
    additional_parameters: {
      mrkdwn: true
    }
  }
end
