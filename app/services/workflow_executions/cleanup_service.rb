# frozen_string_literal: true

module WorkflowExecutions
  # Service used to delete a WorkflowExecution
  class CleanupService < BaseService
    def initialize(workflow_execution, user = nil, params = {})
      super(user, params)
      @workflow_execution = workflow_execution
    end

    def execute
      return if @workflow_execution.cleaned?

      ActiveStorage::Blob.service.delete_prefixed(@workflow_execution.blob_run_directory)

      @workflow_execution.cleaned = true

      @workflow_execution.save

      @workflow_execution
    end
  end
end
