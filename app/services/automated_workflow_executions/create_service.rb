# frozen_string_literal: true

module AutomatedWorkflowExecutions
  # Service used to Create a new AutomatedWorkflowExecution
  class CreateService < BaseService
    def initialize(user = nil, params = {})
      super(user, params)
    end

    def execute
      @automated_workflow_execution = AutomatedWorkflowExecution.new(params.merge(created_by: current_user))

      authorize! @automated_workflow_execution.namespace, to: :create_automated_workflow_execution?

      @automated_workflow_execution.save
    end
  end
end
