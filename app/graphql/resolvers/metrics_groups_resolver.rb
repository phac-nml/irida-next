# frozen_string_literal: true

module Resolvers
  # Metrics Group Resolver
  class MetricsGroupsResolver < BaseResolver
    type Types::MetricGroupType, null: true

    alias parent object

    def resolve(_args)
      return Group.none if parent.blank?

      parent.children
    end
  end
end
