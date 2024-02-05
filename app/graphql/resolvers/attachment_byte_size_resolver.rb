# frozen_string_literal: true

module Resolvers
  # Attachment Byte Size Resolver
  class AttachmentByteSizeResolver < BaseResolver
    type GraphQL::Types::Int, null: false

    alias attachment object

    def resolve
      attachment.file.byte_size
    end
  end
end
