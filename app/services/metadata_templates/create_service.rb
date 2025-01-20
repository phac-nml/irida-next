# frozen_string_literal: true

module MetadataTemplates
  # Service used to Create Metadata Templates
  class CreateService < BaseService
    attr_accessor :namespace

    def initialize(user, namespace, fields = [], params = {})
      super(user, params)
      @namespace = namespace
    end

    def execute
      authorize! namespace, to: :create_metadata_template?
      @metadata_template = build_template
      save_template
      @metadata_template
    rescue StandardError => e
      @metadata_template.errors.add(:base, e.message)
      @metadata_template
    end

    private

    def build_template
      MetadataTemplate.new(params.merge(
        created_by: current_user,
        namespace: namespace,
        fields: fields
      ))
    end

    def save_template
      return unless @metadata_template.save

      @metadata_template.create_activity key: 'namespace.metadata_template.create',
                                       owner: current_user,
                                       parameters: {
                                         template_id: @metadata_template.id,
                                         namespace_id: namespace.id
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
                                           namespace_id: namespace.id
                                         }
      else
        namespace.create_activity key: 'namespaces_project_namespace.metadata_template.create',
                                  owner: current_user,
                                  parameters: {
                                    template_id: @metadata_template.id,
                                    namespace_id: namespace.id
                                  }
      end
    end
  end
end
