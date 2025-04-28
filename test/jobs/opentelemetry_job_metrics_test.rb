# frozen_string_literal: true

require 'test_helper'
require 'minitest/autorun'

class OpenTelemetryJobMetricsTest < ActiveJob::TestCase
  def setup
    # Set up a mock OpenTelemetry Meter to handle calls from the job metrics singleton
    @job_queue_metrics = Irida::JobQueueMetrics.instance
    @mock_meter = Minitest::Mock.new
    @job_queue_metrics.instance_variable_set(:@meter, @mock_meter)
  end

  def teardown
    @mock_meter = nil
    @job_queue_metrics.instance_variable_set(:@meter, nil)
    @job_queue_metrics.instance_variable_set(:@job_queue_count_previous_value_map, nil)
    @job_queue_metrics.instance_variable_set(:@job_queue_latency_previous_value_map, nil)
    @job_queue_metrics.instance_variable_set(:@job_queue_instrument_map, nil)
  end

  class DummyJob < ApplicationJob
    self.queue_adapter = :good_job
    queue_as :default

    def perform(time)
      Rails.logger.info "Performing dummy job with sleep time #{time}"
      sleep time
    end
  end

  test 'metric instrument record' do
    # mock instrument on meter that records values
    mock_instrument = Minitest::Mock.new
    mock_instrument.expect(:record, nil, [234])
    # using 'default' as our queue name
    @mock_meter.expect(:create_gauge, mock_instrument, ['default_queue_count'], description: String)

    # call private method to test basic record
    @job_queue_metrics.instance_eval("metric_update_job_queue_count('default',234)", __FILE__, __LINE__)

    # verify objects called as expected
    assert mock_instrument.verify
    assert @mock_meter.verify
  end

  test 'update queue counts' do
    # mock instrument on meter that records values
    mock_queue_count_instrument = Minitest::Mock.new
    mock_queue_count_instrument.expect(:record, nil, [1])
    # using 'default' as our queue name
    @mock_meter.expect(:create_gauge, mock_queue_count_instrument, ['default_queue_count'], description: String)

    # queue a job
    DummyJob.set(wait: 2.minutes).perform_later(1)
    travel_to(3.minutes.from_now) do
      # run metrics while job is queued
      @job_queue_metrics.update_queue_counts
      # don't let job procs hang
      GoodJob.perform_inline
    end

    # verify objects called as expected
    assert mock_queue_count_instrument.verify
    assert @mock_meter.verify
  end

  test 'update queue latency' do
    # mock instrument on meter that records values
    mock_queue_latency_instrument = Minitest::Mock.new
    mock_queue_latency_instrument.expect(:record, nil) do |latency|
      latency > 55 && latency < 65 # Expect latency to be about a minute
    end
    # using 'default' as our queue name
    @mock_meter.expect(
      :create_gauge, mock_queue_latency_instrument, ['default_queue_min_wait_time'], unit: String, description: String
    )

    # queue a job
    DummyJob.set(wait: 2.minutes).perform_later(1)
    travel_to(3.minutes.from_now) do
      # run metrics while job is queued
      @job_queue_metrics.update_minimum_queue_times
      # don't let job procs hang
      GoodJob.perform_inline
    end

    # verify objects called as expected
    assert mock_queue_latency_instrument.verify
    assert @mock_meter.verify
  end

  test 'update queue count to 0 when queue is empty' do
    # mock instrument on meter that records values
    mock_queue_count_instrument = Minitest::Mock.new
    mock_queue_count_instrument.expect(:record, nil, [3])
    mock_queue_count_instrument.expect(:record, nil, [0])
    # using 'default' as our queue name
    @mock_meter.expect(:create_gauge, mock_queue_count_instrument, ['default_queue_count'], description: String)

    # queue some jobs
    DummyJob.set(wait: 2.minutes).perform_later(1)
    DummyJob.set(wait: 2.minutes).perform_later(1)
    DummyJob.set(wait: 2.minutes).perform_later(1)
    travel_to(3.minutes.from_now) do
      # run metrics while job is queued
      @job_queue_metrics.update_queue_counts
      # run metrics while job is queued AGAIN to verify repeat data points don't get resent
      @job_queue_metrics.update_queue_counts
      # don't let job procs hang
      GoodJob.perform_inline
    end

    # run metrics again after jobs have finished
    @job_queue_metrics.update_queue_counts
    # run metrics again after jobs have finished AGAIN to verify repeat data points don't get resent
    @job_queue_metrics.update_queue_counts

    # verify objects called as expected
    assert mock_queue_count_instrument.verify
    assert @mock_meter.verify
  end

  test 'update queue latency to 0 when queue is empty' do
    # mock instrument on meter that records values
    mock_queue_latency_instrument = Minitest::Mock.new
    mock_queue_latency_instrument.expect(:record, nil) do |latency|
      latency > 55 && latency < 65 # Expect latency to be about a minute
    end
    mock_queue_latency_instrument.expect(:record, nil, [0]) # should be 0 when jobs are cleared
    # using 'default' as our queue name
    @mock_meter.expect(
      :create_gauge, mock_queue_latency_instrument, ['default_queue_min_wait_time'], unit: String, description: String
    )

    # queue some jobs
    DummyJob.set(wait: 2.minutes).perform_later(1)
    DummyJob.set(wait: 2.minutes).perform_later(1)
    DummyJob.set(wait: 2.minutes).perform_later(1)
    travel_to(3.minutes.from_now) do
      # run metrics while job is queued
      @job_queue_metrics.update_minimum_queue_times
      # run metrics while job is queued AGAIN to verify repeat data points don't get resent
      @job_queue_metrics.update_minimum_queue_times
      # don't let job procs hang
      GoodJob.perform_inline
    end

    # run metrics again after jobs have finished
    @job_queue_metrics.update_minimum_queue_times
    # run metrics again after jobs have finished AGAIN to verify repeat data points don't get resent
    @job_queue_metrics.update_minimum_queue_times

    # verify objects called as expected
    assert mock_queue_latency_instrument.verify
    assert @mock_meter.verify
  end
end
