# frozen_string_literal: true

module Resolvers
  # Nested Groups Resolver
  class NestedGroupsResolver < BaseResolver
    type Types::GroupType, null: true

    argument :include_parent_descendants, GraphQL::Types::Boolean,
             required: false,
             description: 'List of descendant groups of the parent group.',
             default_value: true

    alias parent object

    def resolve(args)
      return Group.none if parent.blank?

      if args[:include_parent_descendants]
        parent.descendants.where(type: Group.sti_name)
      else
        parent.children
      end
    end
  end
end
