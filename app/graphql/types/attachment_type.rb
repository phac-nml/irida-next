# frozen_string_literal: true

module Types
  # Attachment Type
  class AttachmentType < Types::BaseType
    implements GraphQL::Types::Relay::Node
    description 'An attachment'

    field :byte_size, Integer, null: false, description: 'Attachment file size'
    field :filename, String, null: false, description: 'Attachment file name'
    field :puid,
          ID,
          null: false,
          description: 'Persistent Unique Identifier of the attachment. For example, `INXT_ATT_AAAAAAAAAAAA`.'

    field :metadata,
          GraphQL::Types::JSON,
          null: false,
          description: 'Metadata for the attachment',
          resolver: Resolvers::AttachmentMetadataResolver

    field :attachment_url, String, null: false, description: 'Attachment download url'

    def attachment_url
      Rails.application.routes.url_helpers.rails_blob_url(object.file)
    end

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
