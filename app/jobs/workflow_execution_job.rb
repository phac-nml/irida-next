# frozen_string_literal: true

# Parent class for Workflow Execution jobs
class WorkflowExecutionJob < ApplicationJob
  def validate_initial_state(workflow_execution, expected_states = nil, validate_run_id: false)
    # check that workflow_execution exists
    return false unless workflow_execution

    # check that workflow_execution has namespace
    return false unless workflow_execution.namespace

    # check that the state is in expected states
    return false if expected_states&.exclude?(workflow_execution.state)

    # check that run_id is on workflow_execution if expected state should have run_id at this point
    return false if validate_run_id && !workflow_execution.run_id

    true
  end

  def handle_error_state_and_clean(workflow_execution)
    # validation must be skipped in the case where model is already invalid (e.g. no namespace)
    workflow_execution.update_attribute('state', :error) # rubocop:disable Rails/SkipsModelValidations
    WorkflowExecutionCleanupJob.perform_later(workflow_execution)
  end
end
