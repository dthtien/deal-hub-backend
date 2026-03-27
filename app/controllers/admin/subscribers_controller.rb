# frozen_string_literal: true

module Admin
  class SubscribersController < BaseController
    def index
      @q = params[:q].to_s.strip
      @status = params[:status].to_s.presence

      scope = Subscriber.order(created_at: :desc)
      scope = scope.where('email ILIKE ?', "%#{@q}%") if @q.present?
      scope = scope.where(status: @status) if @status.present?

      @total   = scope.count
      @page    = (params[:page] || 1).to_i
      per_page = 50
      @total_pages = (@total / per_page.to_f).ceil
      @subscribers = scope.limit(per_page).offset((@page - 1) * per_page)
    end

    def unsubscribe
      subscriber = Subscriber.find(params[:id])
      subscriber.update!(status: 'unsubscribed')
      redirect_to admin_subscribers_path, notice: "#{subscriber.email} has been unsubscribed."
    end
  end
end
