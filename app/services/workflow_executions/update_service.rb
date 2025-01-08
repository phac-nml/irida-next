# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Update a WorkflowExecution
  class UpdateService < BaseService
    def initialize(workflow_execution, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
    end

    def execute
      authorize! @workflow_execution, to: :update?
      @workflow_execution.update!(params)
    end
  end
end
