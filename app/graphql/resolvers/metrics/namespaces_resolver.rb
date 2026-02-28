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

      def resolve(namespace_type:)
        context.scoped_set!(:system_user, true) if context[:current_user].system?
        Namespace.where(type: namespace_type)
      end
    end
  end
end
