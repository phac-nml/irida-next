# frozen_string_literal: true

module MetadataTemplates
  # Service used to Update Metadata Templates
  class UpdateService < BaseService
    class MetadataTemplateUpdateError < StandardError
    end

    def initialize(user = nil, metadata_template = nil, params = {})
      super(user, params)
      @metadata_template = metadata_template
    end

    def execute
      validate_project_not_archived

      authorize! @metadata_template, to: :update_metadata_template?

      updated = @metadata_template.update(params)

      create_activities if updated
      updated
    rescue MetadataTemplates::UpdateService::MetadataTemplateUpdateError => e
      @metadata_template.errors.add(:base, e.message)
      @metadata_template
    end

    private

    def validate_project_not_archived
      return unless @metadata_template.namespace.instance_of?(Namespaces::ProjectNamespace) &&
                    @metadata_template.namespace.archived_at.present?

      raise MetadataTemplateUpdateError,
            I18n.t('services.metadata_templates.update.project_read_only')
    end

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
