# frozen_string_literal: true

module Samples
  # Service used to Create Samples
  class CreateService < BaseService
    attr_accessor :project, :sample

    class CreateError < StandardError
    end

    def initialize(user = nil, project = nil, params = {})
      super(user, params)
      @project = project
      @include_activity = params.key?(:include_activity) ? params[:include_activity] : true
      @sample = Sample.new(params.merge(project_id: project&.id).except(:include_activity))
    end

    def execute # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
      validate_project_not_archived(@project.namespace)

      authorize! @project, to: :create_sample? unless @project.nil?

      if sample.save

        update_samples_count if @project.parent.group_namespace?

        if @include_activity
          @project.namespace.create_activity key: 'namespaces_project_namespace.samples.create',
                                             owner: current_user,
                                             parameters:
                                               {
                                                 sample_id: sample.id,
                                                 sample_puid: sample.puid,
                                                 action: 'sample_create'
                                               }
        end
      end

      sample
    rescue Samples::CreateService::CreateError => e
      @project.namespace.errors.add(:base, e.message)
      sample
    end

    def update_samples_count
      @project.parent.update_samples_count_by_addition_services
    end
  end
end
