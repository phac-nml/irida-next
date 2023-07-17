# frozen_string_literal: true

module Resolvers
  # Project Resolver
  class ProjectResolver < BaseResolver
    argument :full_path, GraphQL::Types::ID,
             required: true,
             description: 'Full path of the project. For example, `pathogen/surveillance/2023`.'

    type Types::ProjectType, null: true

    def resolve(full_path:)
      Namespaces::ProjectNamespace.find_by_full_path(full_path)&.project # rubocop:disable Rails/DynamicFindBy
    end
  end
end
