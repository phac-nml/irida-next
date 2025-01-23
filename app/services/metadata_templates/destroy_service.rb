# frozen_string_literal: true

module MetadataTemplates
  # Service used to Destroy Metadata Templates
  class DestroyService < BaseService
    attr_accessor :namespace

    def initialize(user = nil, metadata_template = nil, params = {})
      super(user, params)
      @metadata_template = metadata_template
    end

    def execute
      authorize! @metadata_template.namespace, to: :destroy_metadata_template?

      @metadata_template.destroy

      create_activities if @metadata_template.deleted?
    end

    def create_activities
      activity_key = if @metadata_template.namespace.group_namespace?
                       'group.metadata_template.destroy'
                     else
                       'namespaces_project_namespace.metadata_template.destroy'
                     end

      @metadata_template.namespace.create_activity key: activity_key,
                                                   owner: current_user,
                                                   parameters: {
                                                     template_name: @metadata_template.name,
                                                     template_id: @metadata_template.id,
                                                     namespace_id: @metadata_template.namespace.id,
                                                     action: 'metadata_template_destroy'
                                                   }
    end
  end
end
