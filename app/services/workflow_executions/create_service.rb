# frozen_string_literal: true

module WorkflowExecutions
  # Service used to Create a new WorkflowExecution
  class CreateService < BaseService
    def initialize(user = nil, params = {})
      super(user, params)
    end

    def execute
      return false if params.empty?

      @workflow_execution = WorkflowExecution.new(params)
      @workflow_execution.submitter = current_user
      @workflow_execution.state = 'new'

      if @workflow_execution.save
        WorkflowExecutionPreparationJob.set(wait_until: 30.seconds.from_now).perform_later(@workflow)
      end

      @workflow_execution
    end
  end
end
