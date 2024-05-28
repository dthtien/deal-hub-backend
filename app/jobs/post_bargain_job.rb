class PostBargainJob < ApplicationJob
  def perform
    service = Deals::Facebook::PostBargain.call

    return if service.success?

    error_message = service.errors.to_sentence
    Rails.logger.error("PostBargainJob failed: #{error_message}")
    ExceptionNotifier.notify_exception(
      StandardError.new(error_message),
      data: { service: }
    )
  end
end
