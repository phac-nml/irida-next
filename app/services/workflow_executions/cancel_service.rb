# frozen_string_literal: true

module WorkflowExecutions
  # Service used to initiate the cancelation of a WorkflowExecution
  class CancelService < BaseService
    include QueryWorkflowExecutionsHelper

    def initialize(user = nil, params = {})
      super(user, {})
      @workflow_execution = params[:workflow_execution] if params[:workflow_execution]
      @workflow_execution_ids = params[:workflow_execution_ids] if params[:workflow_execution_ids]
      @namespace = params[:namespace] if params[:namespace]
    end

    def execute
      @workflow_execution.nil? ? cancel_multiple : cancel_workflow(@workflow_execution)
    end

    private

    def cancel_workflow(workflow_execution) # rubocop:disable Metrics/MethodLength
      return false unless workflow_execution.cancellable?

      authorize! workflow_execution, to: :cancel?

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

      true
    end

    def cancel_multiple
      authorize! @namespace, to: :cancel_workflow_executions? unless @namespace.nil?

      workflow_executions_scope = query_workflow_executions(@namespace)
      cancellable_workflow_executions = workflow_executions_scope.where(
        id: @workflow_execution_ids
      ).where.not(state: %w[completed canceled error])

      successful_cancellations_count = 0
      cancellable_workflow_executions.each do |workflow_execution|
        success = cancel_workflow(workflow_execution)
        successful_cancellations_count += 1 if success
      end

      successful_cancellations_count
    end
  end
end
