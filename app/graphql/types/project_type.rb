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
      super &&
        allowed_to?(
          :read?,
          object,
          context: { user: context[:current_user], token: context[:token] }
        )
    end

    def self.scope_items(items, context)
      scope = authorized_scope Project, type: :relation,
                                        context: { user: context[:current_user], token: context[:token] }
      project_ids = items.pluck(:id)
      scope.where(id: project_ids).in_order_of(:id, project_ids)
    end

    reauthorize_scoped_objects(false)
  end
end
