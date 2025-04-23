# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # if ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT']
  #   after_enqueue do |job|
  #     Irida::JobQueueMetrics.instance.update_job_queue_count(job.queue_name, 1) if job.successfully_enqueued?
  #   end

  #   before_perform do |job|
  #     Irida::JobQueueMetrics.instance.update_job_queue_count(job.queue_name, -1)
  #   end
  # end
end
