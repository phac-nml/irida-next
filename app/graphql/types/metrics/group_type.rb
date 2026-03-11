# frozen_string_literal: true

module Types
  module Metrics
    # Group Type
    class GroupType < Types::BaseType
      implements Types::Metrics::NamespaceWithMetricsType

      graphql_name 'GroupMetricsType'
      description 'Group to get metrics for'

      field :descendant_groups, Types::Metrics::GroupType.connection_type,
            null: true,
            description: 'Subgroups within this group namespace. This field is only available within this type and not
            for the parent type.',
            complexity: 5,
            resolver: Resolvers::Metrics::SubgroupsResolver

      field :members, MemberType.connection_type, null: true, description: 'Members of the group.',
                                                  resolver: Resolvers::Metrics::MembersResolver

      def self.authorized?(object, context)
        super && context[:current_user]&.system?
      end
    end
  end
end
