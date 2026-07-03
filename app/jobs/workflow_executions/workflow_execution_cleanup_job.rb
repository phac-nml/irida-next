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

      step :create_log_attachments
      step :clean_up_blob_run_directory
      step :update_to_cleaned
    end

    private

    def create_log_attachments
      # Create attachments for stdout logs if they exist
      result = WorkflowExecutions::CleanupService.new(@workflow_execution).execute
      run_log = result[:run_log]
      run_stdout = result[:run_stdout]
      files = []
      files << { io: StringIO.new(run_log.to_json), filename: 'run_log.json' } if run_log.present?
      files << { io: StringIO.new(run_stdout.to_json), filename: 'run_stdout.json' } if run_stdout.present?

      Attachments::CreateService.new(@workflow_execution.submitter, @workflow_execution, { files: }).execute
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
