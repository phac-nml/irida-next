# frozen_string_literal: true

module Types
  # Group Type
  class GroupType < NamespaceType
    description 'A group'

    field :descendant_groups, connection_type,
          null: true,
          description: 'List of descendant groups of this group.',
          complexity: 5,
          resolver: Resolvers::NestedGroupsResolver

    field :parent, GroupType, null: true, description: 'Parent group.'
  end
end
