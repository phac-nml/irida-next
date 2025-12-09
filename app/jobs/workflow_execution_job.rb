# frozen_string_literal: true

# Parent class for Workflow Execution jobs
class WorkflowExecutionJob < ApplicationJob
  def validate_initial_state(workflow_execution, expected_states = nil, validate_run_id: false) # rubocop:disable Naming/PredicateMethod
    # check that workflow_execution exists
    return false unless workflow_execution

    # check that workflow_execution has namespace
    return false unless workflow_execution.namespace

    # check that the state is in expected states
    return false if expected_states&.exclude?(workflow_execution.state.to_sym)

    # check that run_id is on workflow_execution if expected state should have run_id at this point
    return false if validate_run_id && !workflow_execution.run_id

    true
  end

  def handle_error_state_and_clean(workflow_execution)
    # validation must be skipped in the case where model is already invalid (e.g. no namespace)
    workflow_execution.update_attribute('state', :error) # rubocop:disable Rails/SkipsModelValidations
    WorkflowExecutionCleanupJob.perform_later(workflow_execution)
  end

  def handle_unable_to_process_job(workflow_execution, job_name)
    error_message = I18n.t('activerecord.errors.models.workflow_execution.invalid_job_state', job_name:)
    Rails.logger.error(error_message)
    handle_error_state_and_clean(workflow_execution)
  end

  def status_check_interval(workflow_execution)
    workflow_execution.workflow.settings.fetch('status_check_interval', 30).to_i
  end

  def maximum_run_time(workflow_execution)
    max_run_time = workflow_execution.workflow.settings.fetch('max_runtime', nil)

    return nil if max_run_time.nil?
    return max_run_time.to_i if max_run_time.is_a?(Integer)

    calculator = Dentaku::Calculator.new
    result = calculator.evaluate(max_run_time, SAMPLE_COUNT: workflow_execution.samples.count)

    result.nil? ? result : result.to_i
  end

  # Calculate time spent in state till now in seconds
  def state_time_calculation(workflow_execution, state)
    change_version = workflow_execution.reload_log_data.data['h'].find do |log|
      log['c']['state'] == WorkflowExecution.states[state]
    end
    # log change version timestamps are in milliseconds
    return Time.zone.now.to_i - (change_version['ts'].to_i / 1000) if change_version

    nil
  end
end
