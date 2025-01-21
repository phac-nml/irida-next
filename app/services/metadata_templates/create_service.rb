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
      authorize! namespace, to: :create_metadata_template?

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
      return if @params[:fields].present?

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
      return unless @metadata_template.save

      @metadata_template.create_activity key: 'namespace.metadata_template.create',
                                         owner: current_user,
                                         parameters: {
                                           template_id: @metadata_template.id,
                                           namespace_id: @namespace.id
                                         }
    end

    def can_create_template?
      authorize! namespace, to: :create_metadata_template?
    end

    def create_activities
      if namespace.group_namespace?
        namespace.parent.create_activity key: 'group.metadata_template.create',
                                         owner: current_user,
                                         parameters: {
                                           template_id: @metadata_template.id,
                                           namespace_id: @namespace.id
                                         }
      else
        namespace.create_activity key: 'namespaces_project_namespace.metadata_template.create',
                                  owner: current_user,
                                  parameters: {
                                    template_id: @metadata_template.id,
                                    namespace_id: @namespace.id
                                  }
      end
    end
  end
end
