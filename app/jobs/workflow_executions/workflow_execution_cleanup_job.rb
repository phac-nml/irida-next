# frozen_string_literal: true

module WorkflowExecutions
  # cleans up workflow execution files no longer needed after completion
  class WorkflowExecutionCleanupJob < WorkflowExecutionJob
    include ActiveJob::Continuable

    queue_as :default
    queue_with_priority 30

    def perform(workflow_execution)
      @workflow_execution = workflow_execution

      # Only run service on runs that can be cleaned
      unless validate_initial_state(
        @workflow_execution, %i[completed error canceled], validate_run_id: false, validate_namespace: false
      )
        return
      end
      # Don't run service if already cleaned
      return if @workflow_execution.nil? || @workflow_execution.cleaned?

      step :workflow_execution_logs
      step :attach_stdout_log
      step :attach_stderr_log
      step :clean_up_blob_run_directory
      step :update_to_cleaned
    end

    private

    def workflow_execution_logs
      @workflow_execution_logs ||= WorkflowExecutions::CleanupService.new(@workflow_execution).execute
    end

    def attach_stdout_log
      return if @workflow_execution.stdout.attached?

      stdout = @workflow_execution_logs[:stdout]

      return if stdout.blank?

      @workflow_execution.stdout.attach(io: StringIO.new(stdout), filename: 'stdout.txt', content_type: 'text/plain')
    end

    def attach_stderr_log
      return if @workflow_execution.stderr.attached?

      stderr = @workflow_execution_logs[:stderr]

      return if stderr.blank?

      @workflow_execution.stderr.attach(io: StringIO.new(stderr), filename: 'stderr.txt', content_type: 'text/plain')
    end

    def clean_up_blob_run_directory
      # This check is for safety as passing nil or an empty string into deleted_prefixed will delete all blobs
      if @workflow_execution.blob_run_directory.present? # rubocop:disable Style/GuardClause
        ActiveStorage::Blob.service.delete_prefixed(@workflow_execution.blob_run_directory)
      end
    end

    def update_to_cleaned
      @workflow_execution.cleaned = true
      @workflow_execution.save
    end
  end
end
