# frozen_string_literal: true

module Resolvers
  # Project Metadata Summary Resolver
  class ProjectMetadataSummaryResolver < BaseResolver
    type GraphQL::Types::JSON, null: false

    argument :keys, [GraphQL::Types::String],
             required: false,
             description: 'Optional array of keys to limit metadata result to.',
             default_value: nil

    alias project object

    def resolve(args)
      scope = project

      return scope.metadata_summary unless args[:keys]

      scope.metadata_summary.slice(*args[:keys])
    end
  end
end
