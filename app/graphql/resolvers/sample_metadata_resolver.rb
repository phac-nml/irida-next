# frozen_string_literal: true

module Resolvers
  # Sample Metadata Resolver
  class SampleMetadataResolver < BaseResolver
    type GraphQL::Types::JSON, null: false

    alias sample object

    def resolve
      scope = sample
      scope.metadata
    end
  end
end
