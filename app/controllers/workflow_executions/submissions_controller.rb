# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionsController < ApplicationController
    include Irida::Pipelines
    cattr_reader :available_pipelines

    respond_to :turbo_stream
    before_action :workflows
    before_action :samples, only: %i[new]
    before_action :workflow, only: %i[new]
    before_action :workflow_schema, only: %i[new]

    def pipeline_selection
      render status: :ok
    end

    def new
      render status: :ok
    end

    private

    def workflows
      @workflows = available_pipelines
    end

    def workflow
      workflow_index = @workflows.index { |workflow| workflow.id == params['workflow_id'].to_i }
      @workflow = @workflows[workflow_index]
    end

    def samples
      sample_ids = params[:sample_ids]
      @samples = Sample.where(id: sample_ids)
    end

    def workflow_schema
      puts workflow.schema_loc
      # Need to get a schema file path from the workflow
      @workflow_schema = JSON.parse(workflow.schema_loc.read)
    end
  end
end
