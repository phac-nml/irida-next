# frozen_string_literal: true

module Resolvers
  # Group Resolver
  class GroupResolver < BaseResolver
    argument :full_path, GraphQL::Types::ID,
             required: false,
             description: 'Full path of the group. For example, `pathogen/surveillance`.'
    argument :puid, GraphQL::Types::ID,
             required: false,
             description: 'Persistent Unique Identifer of the group. For example, `INXT_GRP_GGGGGGGGGG.`'
    validates required: { one_of: %i[full_path puid] }

    def resolve(args)
      if args[:full_path]
        Group.find_by_full_path(args[:full_path]) # rubocop:disable Rails/DynamicFindBy
      else
        Group.find_by(puid: args[:puid])
      end
    end
  end
end
