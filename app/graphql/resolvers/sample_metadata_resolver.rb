# frozen_string_literal: true

module Resolvers
  # Sample Metadata Resolver
  class SampleMetadataResolver < BaseResolver
    type GraphQL::Types::JSON, null: false

    argument :keys, [GraphQL::Types::String],
             required: false,
             description: 'Optional array of keys to limit metadata result to.',
             default_value: nil

    alias sample object

    def resolve(args)
      scope = sample

      return scope.metadata unless args[:keys]

      scope.metadata.slice(*args[:keys])
    end
  end
end
