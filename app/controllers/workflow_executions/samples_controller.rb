# frozen_string_literal: true

module WorkflowExecutions
  # Workflow submission controller
  class SamplesController < ApplicationController
    layout 'workflow_executions'
    before_action :current_page
    before_action :workflow

    def index
      @samples = SamplesWorkflowExecution.where(workflow_execution: @workflow)
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
