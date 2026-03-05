# frozen_string_literal: true

module Resolvers
  module Metrics
    # Namespace Resolver
    class NamespacesResolver < BaseResolver
      graphql_name 'MetricsNamespacesResolver'
      type Types::Metrics::NamespaceWithMetricsType.connection_type, null: true

      argument :namespace_type, [GraphQL::Types::String],
               required: false,
               description: 'Type of namespaces to get metrics for',
               default_value: [Group.sti_name, Namespaces::UserNamespace.sti_name]

      argument :top_level_only, GraphQL::Types::Boolean,
               required: false,
               description: 'Whether to return only top level ancestor namespaces. For example, if true,
                            it will return only top level groups and user namespaces, but not subgroups.',
               default_value: false

      argument :full_path, GraphQL::Types::ID,
               required: false,
               description: 'Full path of the namespace. For example, `pathogen/surveillance`.',
               default_value: nil

      argument :puid, GraphQL::Types::ID,
               required: false,
               description: 'Persistent Unique Identifier of the namespace.
                           For example a group namespace, `INXT_GRP_GGGGGGGGGG.`',
               default_value: nil

      argument :direct_only, GraphQL::Types::Boolean,
               required: false,
               description: 'Whether to return only direct records for the object.
                           For example, if true, it will return only direct records for a namespace,
                           but not records for subgroups.',
               default_value: false

      def resolve(namespace_type:, top_level_only:, full_path:, puid:, direct_only:) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        context.scoped_set!(:system_user, true) if context[:current_user]&.system?

        context.scoped_set!(:direct_only, true) if direct_only

        # Top level Project namespaces are not currently supported for metrics
        # so we remove from the list of namespace types
        namespace_type.delete(Namespaces::ProjectNamespace.sti_name)

        if full_path
          namespace = Namespace.find_by_full_path(full_path) # rubocop:disable Rails/DynamicFindBy
          return [] unless namespace && namespace_type.include?(namespace.type)

          [namespace]
        else
          params = { type: namespace_type }
          params.merge!(puid: puid) if puid
          params.merge!(parent_id: nil) if top_level_only
          Namespace.where(params)
        end
      end
    end
  end
end
