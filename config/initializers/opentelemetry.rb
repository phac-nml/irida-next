# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry-exporter-otlp'

require 'opentelemetry-metrics-sdk'
require 'opentelemetry-exporter-otlp-metrics'

require 'irida/metrics_reporter'

if Flipper.enabled?(:telemetry)
  # Metrics
  ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT'] = 'http://localhost:4318/v1/metrics' # TODO: make this configurable
  ENV['OTEL_METRICS_EXPORTER'] = 'none'

  OpenTelemetry::SDK.configure

  otlp_metric_exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new
  OpenTelemetry.meter_provider.add_metric_reader(otlp_metric_exporter)

  Rails.application.config.after_initialize do
    # start the metrics reporting thread
    Irida::MetricsReporter.instance.run
  end

  at_exit do
    Irida::MetricsReporter.instance.stop
  end
end
