# frozen_string_literal: true

module Resolvers
  # Metrics Project Resolver
  class MetricsProjectsResolver < BaseResolver
    type Types::MetricProjectType, null: true

    alias namespace object

    def resolve
      scope = namespace

      Project.joins(:namespace).where(namespace: { parent: scope })
    end
  end
end
