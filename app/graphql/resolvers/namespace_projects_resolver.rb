# frozen_string_literal: true

module Resolvers
  # Namespace Resolver
  class NamespaceProjectsResolver < BaseResolver
    argument :include_sub_groups, GraphQL::Types::Boolean,
             required: false,
             description: 'Include projects from subgroups.',
             default_value: false

    alias namespace object

    def resolve(args)
      scope = namespace

      scope = scope.self_and_descendants if args[:include_sub_groups]

      Project.joins(:namespace).where(namespace: { parent: scope })
    end
  end
end
