# frozen_string_literal: true

module Admin
  class NotificationsController < BaseController
    def queue
      stats = {}

      begin
        require 'sidekiq/api'

        # Pending jobs per queue
        queues = Sidekiq::Queue.all
        queue_stats = queues.map do |q|
          { name: q.name, size: q.size, latency: q.latency.round(2) }
        end

        # Failed jobs count
        dead_set  = Sidekiq::DeadSet.new
        retry_set = Sidekiq::RetrySet.new
        failed_count = dead_set.size + retry_set.size

        # Next scheduled jobs (next 5)
        scheduled_set = Sidekiq::ScheduledSet.new
        next_scheduled = scheduled_set.first(5).map do |job|
          {
            class:  job.klass,
            at:     Time.at(job.score).iso8601,
            queue:  job['queue']
          }
        end

        stats = {
          queues:          queue_stats,
          failed_count:    failed_count,
          retry_count:     retry_set.size,
          dead_count:      dead_set.size,
          next_scheduled:  next_scheduled,
          generated_at:    Time.current.iso8601
        }
      rescue => e
        stats = { error: "Could not fetch Sidekiq stats: #{e.message}" }
      end

      render json: stats
    end
  end
end
