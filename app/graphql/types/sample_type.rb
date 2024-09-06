# frozen_string_literal: true

module Types
  # Sample Type
  class SampleType < Types::BaseType
    implements GraphQL::Types::Relay::Node
    description 'A sample'

    field :description, String, null: true, description: 'Description of the sample.'
    field :name, String, null: false, description: 'Name of the sample.'
    field :project, ProjectType, null: false, description: 'Project the sample is on.'
    field :puid, ID, null: false,
                     description: 'Persistent Unique Identifier of the sample. For example, `INXT_SAM_AAAAAAAAAAAA`.'

    field :metadata,
          GraphQL::Types::JSON,
          null: false,
          description: 'Metadata for the sample',
          resolver: Resolvers::SampleMetadataResolver

    field :attachments,
          AttachmentType.connection_type,
          null: true,
          description: 'Attachments on the sample',
          resolver: Resolvers::SampleAttachmentsResolver

    field :attachments_updated_at, GraphQL::Types::ISO8601DateTime,
          null: true,
          description: 'Datetime when associated attachments were last updated.'

    def self.authorized?(object, context)
      super &&
        allowed_to?(
          :read_sample?,
          object.project,
          context: { user: context[:current_user], token: context[:token] }
        )
    end

    def self.scope_items(items, context)
      scope = authorized_scope Project, type: :relation,
                                        context: { user: context[:current_user], token: context[:token] }
      Sample.where(id: items.select(:id), project_id: scope.select(:id))
    end

    reauthorize_scoped_objects(false)
  end
end
