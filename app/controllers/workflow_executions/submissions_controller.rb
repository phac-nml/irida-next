# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionsController < ApplicationController
    respond_to :turbo_stream
    before_action :workflows
    before_action :samples, only: %i[create]
    before_action :workflow, only: %i[create]

    def pipeline_selection
      render status: :ok
    end

    def create
      render status: :ok
    end

    private

    def workflows
      @workflows = Irida::Pipelines.available_pipelines
    end

    def workflow
      workflow_name = params[:workflow_name]
      workflow_version = params[:workflow_version]

      @workflow = Irida::Pipelines.find_pipeline_by(workflow_name, workflow_version)
    end

    def samples
      sample_ids = params[:sample_ids]
      @samples = Sample.where(id: sample_ids)
    end
  end
end
