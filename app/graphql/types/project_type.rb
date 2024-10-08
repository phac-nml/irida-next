# frozen_string_literal: true

module Types
  # Project Type
  class ProjectType < Types::BaseType
    implements GraphQL::Types::Relay::Node
    description 'A project'

    field :attachments,
          AttachmentType.connection_type,
          null: true,
          description: 'Attachments on the project',
          resolver: Resolvers::ProjectAttachmentsResolver

    field :description, String, null: true, description: 'Description of the project.'
    field :full_name, String, null: false, description: 'Full name of the project.'
    field :full_path, ID, null: false, description: 'Full path of the project.' # rubocop:disable GraphQL/ExtractType
    field :metadata_summary,
          GraphQL::Types::JSON,
          null: false,
          description: 'Metadata summary for the project',
          resolver: Resolvers::ProjectMetadataSummaryResolver

    field :name, String, null: false, description: 'Name of the project.'
    field :path, String, null: false, description: 'Path of the project.'
    field :puid, ID, null: false,
                     description: 'Persistent Unique Identifier of the project. For example, `INXT_PRJ_AAAAAAAAAA`.'

    field :samples,
          SampleType.connection_type,
          null: true,
          description: 'Samples on the project',
          resolver: Resolvers::ProjectSamplesResolver

    field :parent, NamespaceType, null: false, description: 'Parent namespace'

    def self.authorized?(object, context)
      super && (context[:projects_preauthorized] ||
        allowed_to?(
          :read?,
          object,
          context: { user: context[:current_user], token: context[:token] }
        ))
    end
  end
end
