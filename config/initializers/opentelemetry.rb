# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry-exporter-otlp'

require 'opentelemetry-metrics-sdk'
require 'opentelemetry-exporter-otlp-metrics'

require 'irida/metrics_reporter'

if Flipper.enabled?(:telemetry) && ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT']
  # Metrics endpoint is set by ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT']
  ENV['OTEL_METRICS_EXPORTER'] = 'none'

  OpenTelemetry::SDK.configure

  otlp_metric_exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new
  OpenTelemetry.meter_provider.add_metric_reader(otlp_metric_exporter)

  Rails.application.config.after_initialize do
    # start the metrics reporting thread
    send_interval = ENV['OTEL_METRICS_SEND_INTERVAL']&.to_i || 10
    Irida::MetricsReporter.instance.run(send_interval)
  end

  at_exit do
    Irida::MetricsReporter.instance.stop
  end
end
