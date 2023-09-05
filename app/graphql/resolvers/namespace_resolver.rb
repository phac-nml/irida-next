# frozen_string_literal: true

module Resolvers
  # Namespace Resolver
  class NamespaceResolver < BaseResolver
    argument :full_path, GraphQL::Types::ID,
             required: true,
             description: 'Full path of the namespace. For example, `pathogen/surveillance`.'

    type Types::NamespaceType, null: true

    def resolve(full_path:)
      # Resolve Group or Namespaces::UserNamespace by full path
      Namespace.joins(:route).find_by(route: { path: full_path },
                                      type: [Group.sti_name,
                                             Namespaces::UserNamespace.sti_name])
    end
  end
end
