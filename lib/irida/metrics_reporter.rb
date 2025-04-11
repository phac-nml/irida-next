# frozen_string_literal: true

require 'irida/job_queue_metrics'

require 'singleton'

module Irida
  class MetricsReporter # rubocop:disable Style/Documentation
    include Singleton

    def self.run
      if instance.running?
        Rails.logger.debug { "TelemetryReporter is already running on process #{@proc_id}" }
        return
      end
      unless instance.caller_can_control_reporter?
        Rails.logger.debug { 'TelemetryReporter cannot be run by non primary thread.' }
        return
      end

      instance.run!
    end

    def self.stop
      unless instance.running?
        Rails.logger.debug { 'TelemetryReporter cannot be stopped as it is not running.' }
        return
      end
      unless instance.caller_can_control_reporter?
        Rails.logger.debug { 'TelemetryReporter cannot be stopped by non primary thread.' }
        return
      end

      instance.stop!
    end

    def run!
      @proc_id = Process.pid
      Rails.logger.debug { "Starting TelemetryReporter on process #{@proc_id}" }

      # start the reporting loop
      proc_loop
    end

    def stop!
      Rails.logger.debug { 'Stopping metrics telemetry thread.' }

      @reporter_thread&.terminate
      @reporter_thread = nil
      @proc_id = nil
      OpenTelemetry.meter_provider.shutdown
    end

    def running?
      @proc_id == Process.pid
    end

    def proc_loop
      @reporter_thread = Thread.new do
        loop do
          # run updates for metrics that are collected once per cycle instead of per action
          Irida::JobQueueMetrics.instance.update_minimum_queue_times

          # Batch send all telemetry data
          report

          # TODO: make this configurable
          sleep 10
        end
      end
    end

    # verifies that the current runner is a main process and not a console/runner
    def caller_can_control_reporter?
      console = caller.any? { |call| call.include?('console_command.rb') }
      runner = caller.any? { |call| call.include?('runner_command.rb') }

      !(console || runner)
    end

    private

    def report
      Rails.logger.debug { 'Reporting metrics to telemetry' }

      # batch send telemetry
      OpenTelemetry.meter_provider.metric_readers.each(&:pull)
    end
  end
end
