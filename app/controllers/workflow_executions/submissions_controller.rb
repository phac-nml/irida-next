# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionsController < ApplicationController
    include Irida::Pipelines
    cattr_reader :available_workflows

    respond_to :turbo_stream
    before_action :workflows, only: %i[pipeline_selection new]
    before_action :samples, only: %i[new]
    before_action :workflow_schema, only: %i[new]

    def pipeline_selection
      render status: :ok
    end

    def new
      @workflow = @workflows[1]
      render status: :ok
    end

    private

    def workflows
      @workflows = available_workflows
    end

    def samples
      sample_ids = params[:sample_ids]
      @samples = Sample.where(id: sample_ids)
    end

    def workflow_schema
      schema_loc = @workflows[0].schema_loc

      # Need to get a schema file path from the workflow
      @workflow_schema = JSON.parse(Rails.root.join(schema_loc).read)
    end
  end
end
