# frozen_string_literal: true

module MetadataTemplates
  # Service used to Create Metadata Templates
  class CreateService < BaseService
    attr_accessor :namespace

    def initialize(user = nil, namespace = nil, params = {})
      super(user, params)
      @namespace = namespace
      @member = Member.new(params.merge(created_by: current_user, namespace:))
    end

    def execute(metadata_template)
      # TODO: This authorization is not defined anywhere in the codebase
      # authorize! @namespace, to: :create_metadata_template?

      metadata_template.save!
    end
  end
end
