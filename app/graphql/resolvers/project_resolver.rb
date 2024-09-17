# frozen_string_literal: true

module Resolvers
  # Project Resolver
  class ProjectResolver < BaseResolver
    argument :full_path, GraphQL::Types::ID,
             required: false,
             description: 'Full path of the project. For example, `pathogen/surveillance/2023`.'
    argument :puid, GraphQL::Types::ID,
             required: false,
             description: 'Persistent Unique Identifier of the project. For example, `INXT_PRJ_AAAAAAAAAA`.'
    validates required: { one_of: %i[full_path puid] }

    def resolve(args)
      if args[:full_path]
        Namespaces::ProjectNamespace.find_by_full_path(args[:full_path])&.project # rubocop:disable Rails/DynamicFindBy
      else
        Namespaces::ProjectNamespace.find_by(puid: args[:puid])&.project
      end
    end
  end
end
