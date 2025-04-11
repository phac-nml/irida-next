# frozen_string_literal: true

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

    def run!
      @proc_id = Process.pid
      Rails.logger.debug { "Starting TelemetryReporter on process #{@proc_id}" }
      @count = 1

      # Do setup for metrics reporting

      # start the reporting loop
      proc_loop
    end

    def running?
      @proc_id == Process.pid
    end

    def proc_loop
      @reporter_thread = Thread.new do
        # TODO: do we need this line?
        # Thread.current.thread_variable_set(:fork_safe, true)

        loop do
          report

          # TODO: make this configurable
          sleep 10
        end
      end
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

    def stop!
      Rails.logger.debug { 'Stopping metrics telemetry thread.' }

      @reporter_thread&.terminate
      @reporter_thread = nil
      @proc_id = nil
      OpenTelemetry.meter_provider.shutdown
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
