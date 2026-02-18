# frozen_string_literal: true

require 'csv'
require 'tempfile'

# Queues the workflow execution submission job
class WorkflowExecutionPreparationJob < WorkflowExecutionJob
  include ActiveJob::Continuable
  include BlobHelper

  queue_as :default
  queue_with_priority 20

  def perform(workflow_execution)
    @workflow_execution = workflow_execution
    # User signaled to cancel
    return if @workflow_execution.canceling? || @workflow_execution.canceled?

    step :initial_validation
    step :pipeline_validation
    step :build_run_directory
    step :build_samplesheet
    step :update_state_step
    step :queue_next_job
  end

  private

  def initial_validation
    return if validate_initial_state(@workflow_execution, [:initial], validate_run_id: false)

    update_state(:error, force: true)
  end

  def pipeline_validation
    return if @workflow_execution.state.to_sym == :error

    # confirm pipeline found
    return true if @workflow_execution.workflow&.executable?

    update_state(:error, force: false, cleaned_value: true)
    false
  end

  def build_run_directory
    return if @workflow_execution.state.to_sym == :error

    @workflow_execution.blob_run_directory = generate_run_directory
    @workflow_execution.save
  end

  def build_samplesheet
    return if @workflow_execution.state.to_sym == :error

    WorkflowExecutions::SamplesheetPreparationService.new(@workflow_execution).execute
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

  def update_state(state, force: false, cleaned_value: nil)
    return if @workflow_execution.state.to_sym == state

    if force
      # validation must be skipped in the case where model is already invalid (e.g. no namespace)
      @workflow_execution.update_attribute('state', :error) # rubocop:disable Rails/SkipsModelValidations
    else
      @workflow_execution.state = state
      @workflow_execution.cleaned = cleaned_value unless cleaned_value.nil?
      @workflow_execution.save
    end
  end
end
