# frozen_string_literal: true

module Types
  # Attachment Type
  class AttachmentType < Types::BaseObject
    implements GraphQL::Types::Relay::Node
    description 'An attachment'

    field :byte_size, Integer, null: false, description: 'Attachment file size'
    field :filename, String, null: false, description: 'Attachment file name'

    field :metadata,
          GraphQL::Types::JSON,
          null: false,
          description: 'Metadata for the attachment',
          resolver: Resolvers::AttachmentMetadataResolver

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read?,
          object.attachable.project,
          context: { user: context[:current_user], token: context[:token] }
        )
    end
  end
end
