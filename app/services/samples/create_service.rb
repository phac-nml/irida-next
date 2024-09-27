# frozen_string_literal: true

module Samples
  # Service used to Create Samples
  class CreateService < BaseService
    attr_accessor :project, :sample

    def initialize(user = nil, project = nil, params = {})
      super(user, params)
      @project = project
      @sample = Sample.new(params.merge(project_id: project&.id))
    end

    def execute
      authorize! @project, to: :create_sample? unless @project.nil?

      if sample.save
        @project.namespace.create_activity key: 'namespaces_project_namespace.samples.create',
                                           owner: current_user,
                                           parameters:
                                            {
                                              sample_id: sample.id,
                                              sample_puid: sample.puid,
                                              action: 'sample_create'
                                            }
      end

      update_samples_count if @project.parent.type == 'Group'

      sample
    end

    def update_samples_count
      @project.parent.update_samples_count_by_addition_services
    end
  end
end
