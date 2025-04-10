# frozen_string_literal: true

require 'opentelemetry/sdk'
require 'opentelemetry-exporter-otlp'

require 'opentelemetry-metrics-sdk'
require 'opentelemetry-exporter-otlp-metrics'

require 'irida/metrics_reporter'

# Metrics
ENV['OTEL_EXPORTER_OTLP_METRICS_ENDPOINT'] = 'http://localhost:4318/v1/metrics'
ENV['OTEL_METRICS_EXPORTER'] = 'none'

OpenTelemetry::SDK.configure

otlp_metric_exporter = OpenTelemetry::Exporter::OTLP::Metrics::MetricsExporter.new
OpenTelemetry.meter_provider.add_metric_reader(otlp_metric_exporter)

# start the metrics reporting thread
Irida::MetricsReporter.run
