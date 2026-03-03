# frozen_string_literal: true

module Resolvers
  module Metrics
    # Namespace Resolver
    class NamespacesResolver < BaseResolver
      graphql_name 'MetricsNamespacesResolver'
      type Types::Metrics::NamespaceType.connection_type, null: true

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

      def resolve(namespace_type:, top_level_only:, full_path:, puid:)
        context.scoped_set!(:system_user, true) if context[:current_user].system?

        if full_path
          [Namespace.find_by_full_path(full_path)] # rubocop:disable Rails/DynamicFindBy
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
