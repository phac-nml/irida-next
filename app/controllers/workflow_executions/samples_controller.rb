# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SamplesController < ApplicationController
    layout 'workflow_executions'
    before_action :current_page

    def index
      @workflow = WorkflowExecution.find(params[:workflow_execution_id])
      @samples = SamplesWorkflowExecution.where(workflow_execution: @workflow)
    end

    private

    def current_page
      @current_page = I18n.t(:'projects.sidebar.samples')
    end
  end
end
