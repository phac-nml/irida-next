# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SubmissionsController < ApplicationController
    respond_to :turbo_stream
    # before_action :workflows, only: %i[pipeline_selection]
    before_action :samples, only: %i[new]
    # before_action :workflow_schema, only: %i[new]
    # before_action :workflow, only: %i[new]

    def pipeline_selection
      render status: :ok
    end

    def new
      render status: :ok
    end

    private

    # def workflow
    #   workflow = Struct.new(:name, :id, :description, :version, :metadata, :type, :type_version, :engine,
    #                         :engine_version, :url, :execute_loc)
    #   metadata = { workflow_name: 'irida-next-example', workflow_version: '1.0dev' }
    #   @workflow = workflow.new('phac-nml/iridanextexample', 1, 'IRIDA Next Example Pipeline', '1.0.1', metadata,
    #                            'NFL', 'DSL2', 'nextflow', '23.10.0',
    #                            'https://github.com/phac-nml/iridanextexample', 'azure')
    # end

    # def workflows
    #   @workflows = [workflow]
    # end

    def samples
      sample_ids = params[:sample_ids]
      @samples = Sample.where(id: sample_ids)
    end

    # def workflow_schema
    #   # Need to get a schema file path from the workflow
    #   @workflow_schema = JSON.parse(Rails.root.join('test/fixtures/files/nextflow/nextflow_schema.json').read)
    # end
  end
end
