# frozen_string_literal: true

module Types
  # Group Type
  class GroupType < Types::NamespaceType
    implements GraphQL::Types::Relay::Node
    description 'A group'

    field :attachments,
          AttachmentType.connection_type,
          null: true,
          description: 'Attachments on the group',
          resolver: Resolvers::GroupAttachmentsResolver

    field :descendant_groups, connection_type,
          null: true,
          description: 'List of descendant groups of this group.',
          complexity: 5,
          resolver: Resolvers::NestedGroupsResolver

    field :parent, GroupType, null: true, description: 'Parent group.'

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read?,
          object,
          context: { user: context[:current_user], token: context[:token] }
        )
    end
  end
end
