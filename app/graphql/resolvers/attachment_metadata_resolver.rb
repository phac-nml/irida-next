# frozen_string_literal: true

module Resolvers
  # Attachment Metadata Resolver
  class AttachmentMetadataResolver < BaseResolver
    type GraphQL::Types::JSON, null: false

    argument :keys, [GraphQL::Types::String],
             required: false,
             description: 'Optional array of keys to limit metadata result to.',
             default_value: nil

    alias attachment object

    def resolve(args)
      scope = attachment

      return scope.metadata unless args[:keys]

      scope.metadata.slice(*args[:keys])
    end
  end
end
