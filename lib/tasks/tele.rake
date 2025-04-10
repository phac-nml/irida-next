# frozen_string_literal: true

require 'opentelemetry/sdk'
# require 'opentelemetry/instrumentation/all'
require 'opentelemetry/instrumentation/graphql'
require 'opentelemetry/instrumentation/active_job'
require 'opentelemetry-exporter-otlp'

require 'opentelemetry-metrics-sdk'
require 'opentelemetry-exporter-otlp-metrics'

namespace :tele do
  task send: :environment do
    ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT'] = 'http://localhost:4318/v1/metrics'
    # ENV['OTEL_METRICS_EXPORTER'] = 'http://localhost:4318'
    ENV['OTEL_METRICS_EXPORTER'] = 'none'

    OpenTelemetry::SDK.configure

    otlp_metric_exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new
    OpenTelemetry.meter_provider.add_metric_reader(otlp_metric_exporter)

    meter = OpenTelemetry.meter_provider.meter("SAMPLE_METER_NAME_JEFF")

    histogram = meter.create_histogram('histogram', unit: 'smidgen', description: 'desscription')

    histogram.record(1234, attributes: {'foo' => 'bar'})

    OpenTelemetry.meter_provider.metric_readers.each(&:pull)
    OpenTelemetry.meter_provider.shutdown
  end
end
