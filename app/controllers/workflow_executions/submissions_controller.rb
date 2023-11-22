# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionsController < ApplicationController
    respond_to :turbo_stream
    def pipeline_selection
      respond_to do |format|
        format.turbo_stream do
          @workflows = workflows
          render status: :ok
        end
      end
    end

    def show
      @samples = samples
      @schema = workflow_schema
      @workflow = workflow
      respond_to do |format|
        format.turbo_stream do
          render status: :ok
        end
      end
    end

    private

    def workflow
      workflow = Struct.new(:name, :id, :description, :version)
      workflow.new('Super Awesome Workflow', 1, 'This is a super awesome workflow', '1.0.0')
    end

    def workflows
      workflow = Struct.new(:name, :id, :description, :version)
      awesome_flow = workflow.new('Super Awesome Workflow', 1, 'This is a super awesome workflow', '1.0.0')
      slow_flow = workflow.new('Incredibly Slow Workflow', 2, 'This is a super slow workflow', '0.0.1')
      [awesome_flow, slow_flow]
    end

    def workflow_schema
      # Need to get a schema file path from the workflow
      JSON.parse(Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json').read)
    end

    def samples
      sample_ids = params[:sample_ids]
      @samples = Sample.where(id: sample_ids)
    end
  end
end
