# frozen_string_literal: true

module Resolvers
  # Metrics Resolver
  class MetricsResolver < BaseResolver
    type Types::MetricType, null: true

    def resolve
      object
    end
  end
end
