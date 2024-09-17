# frozen_string_literal: true

module Resolvers
  # Nested Groups Resolver
  class NestedGroupsResolver < BaseResolver
    argument :include_parent_descendants, GraphQL::Types::Boolean,
             required: false,
             description: 'List of descendant groups of the parent group.',
             default_value: true

    alias parent object

    def resolve(args)
      return Group.none if parent.blank?

      if args[:include_parent_descendants]
        parent.descendants
      else
        parent.children
      end
    end
  end
end
