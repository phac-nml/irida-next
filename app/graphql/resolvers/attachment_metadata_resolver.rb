# frozen_string_literal: true

module Resolvers
  # Attachment Metadata Resolver
  class AttachmentMetadataResolver < BaseResolver
    argument :keys, [GraphQL::Types::String],
             required: false,
             description: 'Optional array of keys to limit metadata result to.',
             default_value: nil

    alias attachment object

    def resolve(args)
      return attachment.metadata unless args[:keys]

      attachment.metadata.slice(*args[:keys])
    end
  end
end
