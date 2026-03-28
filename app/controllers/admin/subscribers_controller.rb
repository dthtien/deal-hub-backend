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

      segment_counts = Subscriber.group(:segment).count
      total_subs = Subscriber.count.to_f
      @segments = %w[new active at_risk churned].map do |seg|
        count = segment_counts[seg] || 0
        {
          segment: seg,
          count:   count,
          percent: total_subs > 0 ? (count / total_subs * 100).round(1) : 0
        }
      end

      if request.format.json?
        render json: {
          subscribers: @subscribers.as_json(only: %i[id email status segment confirmed_at created_at]),
          total:        @total,
          page:         @page,
          total_pages:  @total_pages,
          segments:     @segments
        }
      end
    end

    def export
      respond_to do |format|
        format.csv do
          response.headers['Content-Type'] = 'text/csv'
          response.headers['Content-Disposition'] = "attachment; filename=\"subscribers_#{Date.today}.csv\""

          self.response_body = Enumerator.new do |yielder|
            headers = %w[email status segment preferences confirmed_at created_at]
            yielder << CSV.generate_line(headers)

            Subscriber.order(:id).find_each(batch_size: 500) do |sub|
              row = [
                sub.email,
                sub.status,
                sub.segment,
                sub.preferences.present? ? sub.preferences.to_json : '',
                sub.confirmed_at&.strftime('%Y-%m-%d %H:%M:%S'),
                sub.created_at.strftime('%Y-%m-%d %H:%M:%S')
              ]
              yielder << CSV.generate_line(row)
            end
          end
        end
      end
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
