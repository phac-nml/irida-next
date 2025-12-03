# frozen_string_literal: true

module WorkflowExecutions
  # Service used to initiate the cancelation of a WorkflowExecution
  class CancelService < BaseWorkflowExecutionService
    def execute
      if @workflow_execution.nil?
        cancel_multiple
      else
        authorize! @workflow_execution, to: :cancel?
        cancel_workflow(@workflow_execution)
      end
    end

    private

    def cancel_workflow(workflow_execution)
      return false unless workflow_execution.cancellable?

      if workflow_execution.sent_to_ga4gh?
        # Schedule a job to cancel the run on the ga4gh wes server
        workflow_execution.state = :canceling
        workflow_execution.save
        WorkflowExecutionCancelationJob.perform_later(workflow_execution, current_user)
      elsif workflow_execution.initial?
        # No files to clean up, mark as cleaned and do not create a cleanup job.
        workflow_execution.state = :canceled
        workflow_execution.cleaned = true
        workflow_execution.save
      else # state = :prepared
        # Files were generated but not sent to ga4gh, schedule a cleanup job
        workflow_execution.state = :canceled
        workflow_execution.save
        WorkflowExecutionCleanupJob.perform_later(workflow_execution)
      end

      workflow_execution
    end

    def cancel_multiple
      authorize! @namespace, to: :cancel_workflow_executions? unless @namespace.nil?

      workflow_executions_scope = query_workflow_executions
      cancellable_workflow_executions = workflow_executions_scope.where(
        id: @workflow_execution_ids, state: %w[initial prepared submitted running]
      )

      # keep an ongoing count during iteration in case there are state changes before cancel can be completed
      success_count = 0

      cancellable_workflow_executions.each do |workflow_execution|
        success_count += 1 if cancel_workflow(workflow_execution)
      end

      success_count
    end
  end
end
