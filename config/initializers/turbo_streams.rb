# frozen_string_literal: true

Turbo::Streams::BroadcastJob.queue_name = 'transactional_messages'
Turbo::Streams::ActionBroadcastJob.queue_name = 'transactional_messages'
Turbo::Streams::BroadcastStreamJob.queue_name = 'transactional_messages'

if Flipper.enabled?(:telemetry) && ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT']
  # Job metrics reporting monkey patch
  Rails.application.config.after_initialize do
    ts_job_classes = [
      Turbo::Streams::BroadcastJob,
      Turbo::Streams::ActionBroadcastJob,
      Turbo::Streams::BroadcastStreamJob
    ]
    ts_job_classes.each do |c|
      c.class_eval do
        after_enqueue do |job|
          Irida::JobQueueMetrics.instance.update_job_queue_count(job.queue_name, 1) if job.successfully_enqueued?
        end

        before_perform do |job|
          Irida::JobQueueMetrics.instance.update_job_queue_count(job.queue_name, -1)
        end
      end
    end
  end
end
