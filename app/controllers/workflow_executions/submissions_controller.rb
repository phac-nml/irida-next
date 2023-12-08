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
      @workflow_schema = workflow_schema
      @workflow = workflow
      respond_to do |format|
        format.turbo_stream do
          render status: :ok
        end
      end
    end

    def create
      @workflow_execution = workflow_execution
      respond_to do |format|
        format.turbo_stream do
          render status: :ok
        end
      end
    end

    private

    def workflow
      workflow = Struct.new(:name, :id, :description, :version, :metadata)
      metadata = { workflow_name: 'irida-next-example', workflow_version: '1.0dev' }
      workflow.new('Super Awesome Workflow', 1, 'This is a super awesome workflow', '1.0.0', metadata)
    end

    def workflows
      workflow = Struct.new(:name, :id, :description, :version)
      awesome_flow = workflow.new('Super Awesome Workflow', 1, 'This is a super awesome workflow', '1.0.0')
      slow_flow = workflow.new('Incredibly Slow Workflow', 2, 'This is a super slow workflow', '0.0.1')
      [awesome_flow, slow_flow]
    end

    def workflow_execution_metadata_param
      params.require(:metadata)
    end

    def workflow_execution_samples_params
      params.require(:sample)
    end

    def workflow_execution
      @workflow_execution = WorkflowExecution.new
      @workflow_execution.metadata = workflow_execution_metadata_param
      @workflow_execution.submitter_id = current_user.id
      workflow_execution_samples_params.each_key do |key|
        item = samples[key]
        sample = item['name']
        fastq_1 = item['fastq_1']
        fastq_2 = item['fastq_2'] if item['fastq_2'].present?
      end
      @workflow_execution
    end

    def samples
      sample_ids = params[:sample_ids]
      @samples = Sample.where(id: sample_ids)
    end

    def workflow_schema
      # Need to get a schema file path from the workflow
      JSON.parse(Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json').read)
    end
  end
end
