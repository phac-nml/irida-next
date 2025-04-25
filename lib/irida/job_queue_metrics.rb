# frozen_string_literal: true

require 'singleton'

module Irida
  # Functions for creating instruments and updating values on metrics meter
  class JobQueueMetrics
    include Singleton

    def update_minimum_queue_times
      now = Time.now.utc
      time_by_queue = GoodJob::Job
                      .queued
                      .group(:queue_name)
                      .pluck(:queue_name, Arel.sql('min(coalesce(scheduled_at, created_at))'))
                      .to_h

      latency_hash = {}
      time_by_queue.each do |queue_name, queue_time|
        latency = queue_time ? (now - queue_time).ceil : 0 # seconds
        latency_hash[queue_name] = latency
      end

      latency_to_send = build_data_to_send(latency_hash, job_queue_latency_previous_value_map)

      latency_to_send.each do |queue_name, latency|
        metric_update_queue_min_latency(queue_name, latency)
      end
    end

    def update_queue_counts
      queue_counts = GoodJob::Job
                     .queued
                     .group(:queue_name)
                     .count

      queue_counts_to_send = build_data_to_send(queue_counts, job_queue_count_previous_value_map)

      queue_counts_to_send.each do |queue_name, count|
        metric_update_job_queue_count(queue_name, count)
      end
    end

    private

    def meter
      @meter ||= OpenTelemetry.meter_provider.meter('JOB_QUEUE_METER')
    end

    def job_queue_count_previous_value_map
      @job_queue_count_previous_value_map ||= {}
    end

    def job_queue_latency_previous_value_map
      @job_queue_latency_previous_value_map ||= {}
    end

    # This method reduces number of call to the instruments by
    #  only reporting when the value is different than what was sent previously
    # It also includes a 0 when a value was previously passed but is not reported by GoodJob
    #  This prevents the issue of large counts/latency being shown on metrics graphs when the queue's are actually empty
    def build_data_to_send(data_map, previous_data_map) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      data_to_send = {}
      keys = (data_map.keys + previous_data_map.keys).uniq
      keys.each do |queue_name|
        if previous_data_map.key?(queue_name)
          if data_map.key?(queue_name)
            # unless this is a new value, don't update it
            unless previous_data_map[queue_name] == data_map[queue_name]
              previous_data_map[queue_name] = data_map[queue_name]
              data_to_send[queue_name] = data_map[queue_name]
            end
          else
            # queue_name not in GoodJob query, so its value is 0
            # unless this is a new value, don't update it
            unless previous_data_map[queue_name].zero?
              previous_data_map[queue_name] = 0
              data_to_send[queue_name] = 0
            end
          end
        else
          previous_data_map[queue_name] = data_map[queue_name]
          data_to_send[queue_name] = data_map[queue_name]
        end
      end

      data_to_send
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
      if instrument_type == :queue_count
        meter.create_gauge(
          instrument_name, description: 'Current number of jobs in queue'
        )
      else # queue_latency
        meter.create_gauge(
          instrument_name, unit: 's', description: 'Minimum time a queued job is waiting to be performed.'
        )
      end
    end

    def metric_update_job_queue_count(queue_name, value)
      job_queue_count_instrument_name = "#{queue_name}_queue_count"
      instrument = get_instrument(job_queue_count_instrument_name, :queue_count)
      instrument.record(value)
    end

    def metric_update_queue_min_latency(queue_name, value)
      job_queue_latency_instrument_name = "#{queue_name}_queue_min_wait_time"
      instrument = get_instrument(job_queue_latency_instrument_name, :queue_latency)
      instrument.record(value)
    end
  end
end
