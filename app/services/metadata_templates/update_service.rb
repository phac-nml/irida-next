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
      authorize! @metadata_template.namespace, to: :update_metadata_template?

      validate_params

      return false unless @metadata_template.update(params)

      create_activities
      true
    rescue MetadataTemplates::UpdateService::MetadataTemplateUpdateError => e
      @metadata_template.errors.add(:base, e.message)
    end

    private

    def validate_params
      return unless @params[:fields].blank? || !@params[:fields].is_a?(Array)

      raise MetadataTemplateUpdateError,
            I18n.t('services.metadata_templates.create.required.fields')
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
