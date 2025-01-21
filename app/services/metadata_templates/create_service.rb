# frozen_string_literal: true

module MetadataTemplates
  # Service used to Create Metadata Templates
  class CreateService < BaseService
    MetadataTemplateCreateError = Class.new(StandardError)

    attr_accessor :namespace

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
      authorize! namespace, to: :create_metadata_template?

      validate_params

      save_template
      @metadata_template
    rescue MetadataTemplates::CreateService::MetadataTemplateCreateError => e
      @metadata_template.errors.add(:base, e.message)
      @metadata_template
    end

    private

    def validate_params
      if @params[:name].blank?
        raise MetadataTemplateCreateError,
              I18n.t('services.metadata_templates.create.required.name')
      end
      return if @params[:fields].present?

      raise MetadataTemplateCreateError,
            I18n.t('services.metadata_templates.create.required.fields')
    end

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
