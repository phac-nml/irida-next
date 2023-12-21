# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SamplesController < ApplicationController
    layout 'workflow_executions'
    before_action :current_page
    before_action :workflow, only: %i[index]

    def index
      samples = {}

      SamplesWorkflowExecution.where(workflow_execution: @workflow).each do |record|
        samples[record.sample.id] = record.sample
      end

      @samples = []
      @workflow.samples_workflow_executions.each do |params|
        s = samples[params.sample_id] # actual sample

        files = []
        params.samplesheet_params.each do |_key, value|
          matches = value.match(%r{/(\d+)$})
          next unless matches

          id = matches[1]
          s.attachments.each do |file|
            files << file.file if file.file.id == id.to_i
          end
        end

        @samples << { sample: s, files: }
      end
    end

    private

    def workflow
      @workflow = WorkflowExecution.find(params[:workflow_execution_id])
    end

    def current_page
      @current_page = I18n.t(:'projects.sidebar.samples')
    end
  end
end
