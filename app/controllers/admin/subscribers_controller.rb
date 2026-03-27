# frozen_string_literal: true

require 'csv'

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

    def import
      unless request.post?
        redirect_to admin_subscribers_path
        return
      end

      file = params[:csv_file]
      unless file.present?
        redirect_to admin_subscribers_path, alert: 'Please select a CSV file.'
        return
      end

      imported = 0
      skipped  = 0
      errors   = []

      begin
        csv_text = file.read.force_encoding('UTF-8')
        csv = CSV.parse(csv_text, headers: true)

        unless csv.headers.map(&:to_s).map(&:downcase).include?('email')
          redirect_to admin_subscribers_path, alert: 'CSV must have an "email" column.'
          return
        end

        csv.each_with_index do |row, idx|
          email = row['email']&.strip&.downcase
          if email.blank?
            skipped += 1
            next
          end

          if Subscriber.exists?(email: email)
            skipped += 1
          else
            sub = Subscriber.new(email: email, status: 'active')
            if sub.save
              imported += 1
            else
              errors << "Row #{idx + 2}: #{sub.errors.full_messages.join(', ')}"
              skipped += 1
            end
          end
        end
      rescue CSV::MalformedCSVError => e
        redirect_to admin_subscribers_path, alert: "CSV parse error: #{e.message}"
        return
      end

      notice = "Import complete: #{imported} imported, #{skipped} skipped."
      notice += " Errors: #{errors.first(5).join('; ')}" if errors.any?
      redirect_to admin_subscribers_path, notice: notice
    end
  end
end
