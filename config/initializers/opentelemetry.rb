# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry-exporter-otlp'

require 'opentelemetry-metrics-sdk'
require 'opentelemetry-exporter-otlp-metrics'

require 'irida/metrics_reporter'

# Do not continue if OTEL EXPORTER endpoints are not set
return unless ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT'] || ENV['OTEL_EXPORTER_OTLP_TRACES_ENDPOINT']

# Before SDK Configure, disable default metric exporter if we defined the endpoint
if ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT']
  # We will define our own otlp metric exporter
  ENV['OTEL_METRICS_EXPORTER'] = 'none'
end

# Configure the SDK depending on which endpoints are active
if ENV['OTEL_EXPORTER_OTLP_TRACES_ENDPOINT']
  OpenTelemetry::SDK.configure do |c|
    c.use 'OpenTelemetry::Instrumentation::ActiveJob'
  end
else
  OpenTelemetry::SDK.configure
end

# Configure our custom metrics reporter
if ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT']
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
