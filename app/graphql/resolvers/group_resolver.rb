# frozen_string_literal: true

module Resolvers
  # Group Resolver
  class GroupResolver < BaseResolver
    argument :full_path, GraphQL::Types::ID,
             required: true,
             description: 'Full path of the group. For example, `pathogen/surveillance`.'

    type Types::GroupType, null: true

    def resolve(full_path:)
      Group.find_by_full_path(full_path) # rubocop:disable Rails/DynamicFindBy
    end
  end
end
