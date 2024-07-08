# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Service used to Create a new AutomatedWorkflowExecution
  class CreateService < BaseService
    def initialize(user = nil, params = {})
      super
    end

    def execute
      @automated_workflow_execution = AutomatedWorkflowExecution.new(params.merge(created_by: current_user))
      namespace = @automated_workflow_execution.namespace

      authorize! namespace, to: :create_automated_workflow_executions? if namespace.present?

      @automated_workflow_execution.save

      @automated_workflow_execution
    end
  end
end
