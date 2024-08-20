# frozen_string_literal: true

module Samples
  # Service used to Update Samples
  class UpdateService < BaseService
    attr_accessor :sample

    def initialize(sample, user = nil, params = {})
      super(user, params.except(:sample, :id))
      @sample = sample
    end

    def execute
      authorize! sample.project, to: :update_sample?

      sample_updated = sample.update(params)

      if sample_updated
        sample.project.namespace.create_activity key: 'namespaces_project_namespace.samples.update',
                                                 owner: current_user,
                                                 parameters:
                                                  {
                                                    sample_id: sample.id,
                                                    sample_name: sample.name,
                                                    action: 'sample_update'
                                                  }
      end

      sample_updated
    end
  end
end
