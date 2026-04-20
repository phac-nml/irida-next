# frozen_string_literal: true

require 'csv'
require 'tempfile'

module WorkflowExecutions
  # Queues the workflow execution submission job
  class WorkflowExecutionPreparationJob < WorkflowExecutionJob
    include ActiveJob::Continuable
    include BlobHelper
    include SamplesheetPreparationHelper

    queue_as :default
    queue_with_priority 20

    def perform(workflow_execution)
      @workflow_execution = workflow_execution
      # User signaled to cancel
      return if @workflow_execution.canceling? || @workflow_execution.canceled?

      step :initial_validation
      step :pipeline_validation
      step :build_run_directory
      step :copy_attachments_to_run_dir, start: [0, 0]
      step :build_samplesheet
      step :update_state_step
      step :queue_next_job
    end

    private

    def initial_validation
      return if validate_initial_state(@workflow_execution, [:initial], validate_run_id: false)

      update_state(:error)
    end

    def pipeline_validation
      return if @workflow_execution.state.to_sym == :error

      # confirm pipeline found
      return true if @workflow_execution.workflow&.executable?

      update_state(:error, cleaned_value: true)
      false
    end

    def build_run_directory
      return if @workflow_execution.state.to_sym == :error

      @workflow_execution.blob_run_directory = generate_run_directory
      @workflow_execution.save
    end

    def copy_attachments_to_run_dir(step)
      return if @workflow_execution.state.to_sym == :error

      execute_copy_step(@workflow_execution, step)
    end

    def build_samplesheet
      return if @workflow_execution.state.to_sym == :error

      execute_processing_step(@workflow_execution)
    end

    def queue_next_job
      if @workflow_execution.state.to_sym == :error
        WorkflowExecutionCleanupJob.perform_later(@workflow_execution.reload)
      else
        WorkflowExecutionSubmissionJob.perform_later(@workflow_execution.reload)
      end
    end

    def update_state_step
      return if @workflow_execution.state.to_sym == :error

      update_state(:prepared)
    end
  end
end
