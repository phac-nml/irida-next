# frozen_string_literal: true

module Resolvers
  module Metrics
    # Subgroups Resolver
    class SubgroupsResolver < BaseResolver
      graphql_name 'MetricsSubgroupsResolver'
      type Types::Metrics::GroupType, null: true

      alias parent object

      def resolve
        return if parent.user_namespace?

        return Group.none if parent.blank?

        parent.children
      end
    end
  end
end
