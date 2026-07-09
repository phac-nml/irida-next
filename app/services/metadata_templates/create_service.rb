# frozen_string_literal: true

module MetadataTemplates
  # Service used to Create Metadata Templates
  class CreateService < BaseService
    attr_accessor :namespace

    class MetadataTemplatesCreateError < StandardError
    end

    def initialize(user, namespace, params = {})
      super(user, params)
      @namespace = namespace
      @params = params
      @metadata_template = MetadataTemplate.new(params.merge(
                                                  created_by: current_user,
                                                  namespace: namespace
                                                ))
    end

    def execute
      validate_project_not_archived(@namespace) if @namespace.project_namespace?

      authorize! namespace, to: :create_metadata_templates?
      save_template
      @metadata_template
    rescue MetadataTemplates::CreateService::MetadataTemplatesCreateError => e
      @metadata_template.errors.add(:base, e.message)
      @metadata_template
    end

    private

    def save_template
      @metadata_template.save

      create_activities if @metadata_template.persisted?
    end

    def create_activities
      activity_key = if namespace.group_namespace?
                       'group.metadata_template.create'
                     else
                       'namespaces_project_namespace.metadata_template.create'
                     end
      namespace.create_activity key: activity_key,
                                owner: current_user,
                                parameters: {
                                  template_id: @metadata_template.id,
                                  template_name: @metadata_template.name,
                                  namespace_id: @namespace.id,
                                  action: 'metadata_template_create'
                                }
    end
  end
end
