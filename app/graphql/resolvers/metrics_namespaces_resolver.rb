# frozen_string_literal: true

module Resolvers
  # Namespace Resolver
  class MetricsNamespacesResolver < BaseResolver
    type Types::MetricNamespaceType.connection_type, null: true

    def resolve
      context.scoped_set!(:system_user, true) if context[:current_user].system?
      Namespace.where(type: [Group.sti_name, Namespaces::UserNamespace.sti_name])
    end
  end
end
