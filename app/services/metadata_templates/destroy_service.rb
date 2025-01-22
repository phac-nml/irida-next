# frozen_string_literal: true

module MetadataTemplates
  # Service used to Destroy Metadata Templates
  class DestroyService < BaseService
    attr_accessor :namespace

    def initialize(user = nil, metadata_template = nil, params = {})
      super(user, params)
      @metadata_template = metadata_template
    end

    def execute
      authorize! @metadata_template.namespace, to: :destroy_metadata_template?

      @metadata_template.destroy
    end
  end
end
