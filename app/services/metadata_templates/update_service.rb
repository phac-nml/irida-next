# frozen_string_literal: true

module MetadataTemplates
  # Service used to Update Metadata Templates
  class UpdateService < BaseService
    MetadataTemplateUpdateError = Class.new(StandardError)

    def initialize(user = nil, metadata_template = nil, params = {})
      super(user, params)
      @metadata_template = metadata_template
    end

    def execute
      authorize! @metadata_template.namespace, to: :update_metadata_templates?

      updated = @metadata_template.update(params)

      create_activities if updated
      @metadata_template
    end

    private

    def create_activities
      activity_key = if @metadata_template.namespace.group_namespace?
                       'group.metadata_template.update'
                     else
                       'namespaces_project_namespace.metadata_template.update'
                     end

      @metadata_template.namespace.create_activity(
        key: activity_key,
        owner: current_user,
        parameters: {
          template_name: @metadata_template.name,
          template_id: @metadata_template.id,
          namespace_id: @metadata_template.namespace.id,
          action: 'metadata_template_update'
        }
      )
    end
  end
end
