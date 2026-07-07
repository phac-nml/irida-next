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

    def create_log_attachments # rubocop:disable Metrics/AbcSize
      run_log_filename = 'run_log.json'
      run_stdout_filename = 'run_stdout.txt'
      existing_output_filenames = @workflow_execution.outputs.map { |output| output.filename.to_s }

      if existing_output_filenames.include?(run_log_filename) || existing_output_filenames.include?(run_stdout_filename)
        return
      end

      # Create attachments for pipeline run & stdout logs if they exist
      result = WorkflowExecutions::CleanupService.new(@workflow_execution).execute
      run_log = result[:run_log]
      run_stdout = result[:run_stdout]
      files = []

      files << { io: StringIO.new(sanitize(run_log.to_json)), filename: run_log_filename } if run_log.present?
      files << { io: StringIO.new(sanitize(run_stdout)), filename: run_stdout_filename } if run_stdout.present?

      return if files.empty?

      Attachments::CreateService.new(@workflow_execution.submitter, @workflow_execution, { files: }).execute
    end

    def sanitize(text)
      text.encode('US-ASCII', invalid: :replace, undef: :replace, replace: '')
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
