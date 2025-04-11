# frozen_string_literal: true

require 'singleton'

module Irida
  class JobQueueMetrics # rubocop:disable Style/Documentation
    include Singleton

    def update_minimum_queue_times
      now = Time.now.utc
      time_by_queue = GoodJob::Job
                      .where(performed_at: nil, finished_at: nil)
                      .group(:queue_name)
                      .pluck(:queue_name, Arel.sql('min(coalesce(scheduled_at, created_at))'))
                      .to_h

      time_by_queue.each do |queue_name, queue_time|
        latency = queue_time ? (now - queue_time).ceil : 0 # seconds
        metric_update_queue_min_latency(queue_name, latency)
      end
    end

    def update_job_queue_count(queue_name, value)
      metric_update_job_queue_count(queue_name, value)
    end

    # def update_queue_counts
    #   queue_counts = ::GoodJob::Job.running.group(:queue_name).count
    #
    #   queue_counts.each do |queue_name, count|
    #     # For this to work, we would need to change from an updown to a guage
    #     metric_update_job_queue_count(queue_name, count)
    #   end
    # end

    private

    def meter
      @meter ||= OpenTelemetry.meter_provider.meter("JOB_QUEUE_METER")
    end

    def job_queue_instrument_map
      @job_queue_instrument_map ||= {}
    end

    def get_instrument(instrument_name, instrument_type)
      unless job_queue_instrument_map.key?(instrument_name)
        job_queue_instrument_map[instrument_name] = init_instrument(instrument_name, instrument_type)
      end

      job_queue_instrument_map[instrument_name]
    end

    def init_instrument(instrument_name, instrument_type)
      if instrument_type == :up_down
        meter.create_up_down_counter(
          instrument_name, description: 'Current number of jobs in queue'
        )
      else # gauge
        meter.create_gauge(
          instrument_name, unit: 's', description: 'Minimum time a queued job is waiting to be performed.'
        )
      end
    end

    def metric_update_job_queue_count(queue_name, value)
      job_queue_count_instrument_name = "#{queue_name}_queue_count"
      instrument = get_instrument(job_queue_count_instrument_name, :up_down)
      instrument.add(value)
    end

    def metric_update_queue_min_latency(queue_name, value)
      job_queue_latency_instrument_name = "#{queue_name}_queue_min_wait_time"
      instrument = get_instrument(job_queue_latency_instrument_name, :gauge)
      instrument.record(value)
    end
  end
end
