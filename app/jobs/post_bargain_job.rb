class PostBargainJob < ApplicationJob
  def perform
    service = Deals::Facebook::PostBargain.call

    return if service.success?

    Rails.logger.error(service.errors)
    ExceptionNotifier.notify_exception(service.errors, data: { service: })
  end
end
