# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SamplesController < ApplicationController
    layout 'workflow_executions'
    before_action :current_page
    before_action :workflow, only: %i[index]

    def index
      @samples = []
      @workflow.samples_workflow_executions.each do |params|
        sample = params.sample

        files = []
        params.samplesheet_params.each do |_key, value|
          matches = value.match(%r{/(\d+)$})
          next unless matches

          id = matches[1]
          sample.attachments.each do |file|
            files << file.file if file.file.id == id.to_i
          end
        end

        @samples << { sample:, files: }
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
