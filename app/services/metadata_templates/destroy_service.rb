# frozen_string_literal: true

module MetadataTemplates
  # Service used to Destroy Metadata Templates
  class DestroyService < BaseService
    attr_accessor :namespace

    class MetadataTemplatesDestroyError < StandardError
    end

    def initialize(user = nil, metadata_template = nil, params = {})
      super(user, params)
      @metadata_template = metadata_template
    end

    def execute
      validate_project_not_archived

      authorize! @metadata_template, to: :destroy_metadata_template?

      @metadata_template.destroy

      create_activities if @metadata_template.deleted?
    rescue MetadataTemplates::DestroyService::MetadataTemplatesDestroyError => e
      @metadata_template.errors.add(:base, e.message)
      @metadata_template
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
                                                     template_id: @metadata_template.id,
                                                     template_name: @metadata_template.name,
                                                     namespace_id: @metadata_template.namespace.id,
                                                     action: 'metadata_template_destroy'
                                                   }
    end

    private

    def validate_project_not_archived
      return unless @metadata_template.namespace.instance_of?(Namespaces::ProjectNamespace) &&
                    @metadata_template.namespace.archived_at.present?

      raise MetadataTemplatesDestroyError,
            I18n.t('services.metadata_templates.destroy.project_read_only')
    end
  end
end
