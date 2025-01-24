# frozen_string_literal: true

module MetadataTemplates
  # Service used to Create Metadata Templates
  class CreateService < BaseService
    MetadataTemplateCreateError = Class.new(StandardError)
    attr_accessor :namespace

    def initialize(user, namespace, params = {})
      super(user, params)
      @metadata_template = nil
      @namespace = namespace
      @params = params
    end

    def execute
      authorize! namespace, to: :create_metadata_templates?

      validate_params

      build_template
      save_template
      @metadata_template
    rescue MetadataTemplates::CreateService::MetadataTemplateCreateError => e
      @namespace.errors.add(:base, e.message)
    end

    private

    def validate_params
      if @params[:name].blank?
        raise MetadataTemplateCreateError,
              I18n.t('services.metadata_templates.create.required.name')
      end

      return unless @params[:fields].blank? || !@params[:fields].is_a?(Array)

      raise MetadataTemplateCreateError,
            I18n.t('services.metadata_templates.create.required.fields')
    end

    def build_template
      @metadata_template = MetadataTemplate.new(@params.merge(
                                                  created_by: current_user,
                                                  namespace: @namespace
                                                ))
    end

    def save_template
      unless @metadata_template.save
        raise MetadataTemplateCreateError,
              @namespace.errors.add(:base, @metadata_template.errors.full_messages.first)
      end

      create_activities
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
