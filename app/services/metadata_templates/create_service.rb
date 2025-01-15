# frozen_string_literal: true

module MetadataTemplates
  # Service used to Create Metadata Templates
  class CreateService < BaseService
    attr_accessor :namespace

    def initialize(user, namespace, fields = [], params = {})
      super(user, params)
      @namespace = namespace
      @metadata_template = MetadataTemplate.new(params.merge(
                                                  created_by: current_user,
                                                  namespace: namespace,
                                                  fields: fields
                                                ))
    end

    def execute
      return error('Unauthorized') unless can_create_template?

      error(@metadata_template.errors.full_messages) unless @metadata_template.valid?
    end

    private

    def can_create_template?
      # Define authorization logic here
      # Example: current_user.can?(:create_metadata_template, namespace)
      true # Replace with actual authorization check
    end
  end
end
