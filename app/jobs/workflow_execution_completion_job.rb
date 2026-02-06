# frozen_string_literal: true

# Queues the workflow execution completion job
class WorkflowExecutionCompletionJob < WorkflowExecutionJob
  queue_as :default
  queue_with_priority 10

  def perform(workflow_execution)
    @workflow_execution = workflow_execution

    unless validate_initial_state(@workflow_execution, [:completing], validate_run_id: false)
      update_state(:error, force: true)
    end

    # Steps
    run_service

    merge_metadata_onto_samples
    put_output_attachments_onto_samples
    create_activities

    update_state(:completed)
    queue_next_job
  end

  private

  def run_service
    return if @workflow_execution.state.to_sym == :error

    WorkflowExecutions::CompletionService.new(workflow_execution).execute
  end

  def merge_metadata_onto_samples
    return if @workflow_execution.state.to_sym == :error
    return unless @workflow_execution.update_samples?

    @workflow_execution.samples_workflow_executions&.each do |swe|
      # TODO: Cursor
      next if swe.sample.nil? || swe.metadata.nil?

      params = {
        'metadata' => swe.metadata,
        'analysis_id' => @workflow_execution.id,
        include_activity: false,
        'force_update' => true
      }
      Samples::Metadata::UpdateService.new(
        swe.sample.project, swe.sample, current_user, params
      ).execute
    end
  end

  def put_output_attachments_onto_samples
    return if @workflow_execution.state.to_sym == :error
    return unless @workflow_execution.update_samples?

    @workflow_execution.samples_workflow_executions&.each do |swe|
      # TODO: Cursor
      next if swe.sample.nil? || swe.outputs.empty?

      files = swe.outputs.map { |output| output.file.signed_id }
      params = { files:, include_activity: false }
      Attachments::CreateService.new(
        current_user, swe.sample, params
      ).execute
    end
  end

  def create_activities # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    return if @workflow_execution.state.to_sym == :error
    return unless @workflow_execution.update_samples?
    return unless @workflow_execution.submitter.automation_bot?

    @workflow_execution.samples_workflow_executions&.each do |swe|
      # TODO: Cursor
      next if swe.sample.nil? || (swe.metadata.nil? && swe.outputs.empty?)

      parameters = { workflow_id: @workflow_execution.id, sample_id: swe.sample.id, sample_puid: swe.sample.puid }

      if !swe.metadata.nil? && !swe.outputs.empty?
        @workflow_execution.namespace.create_activity(
          key: 'workflow_execution.automated_workflow_completion.outputs_and_metadata_written', parameters:
        )
        next
      end

      unless swe.metadata.nil?
        @workflow_execution.namespace.create_activity(
          key: 'workflow_execution.automated_workflow_completion.metadata_written', parameters:
        )
      end

      next if swe.outputs.empty?

      @workflow_execution.namespace.create_activity(
        key: 'workflow_execution.automated_workflow_completion.outputs_written', parameters:
      )
    end
  end

  def update_state(state, force: false)
    return if @workflow_execution.state.to_sym == state

    if force
      # validation must be skipped in the case where model is already invalid (e.g. no namespace)
      @workflow_execution.update_attribute('state', :error) # rubocop:disable Rails/SkipsModelValidations
    else
      @workflow_execution.state = state
      @workflow_execution.save
    end
  end

  def queue_next_job
    @workflow_execution.reload
    case @workflow_execution.state.to_sym
    when :completed, :error
      WorkflowExecutionCleanupJob.perform_later(@workflow_execution)
    else
      # TODO: is there even an alt case possible??
    end
  end
end
