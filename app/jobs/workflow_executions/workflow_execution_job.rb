# frozen_string_literal: true

module WorkflowExecutions
  # Parent class for Workflow Execution jobs
  class WorkflowExecutionJob < ApplicationJob
    def validate_initial_state(workflow_execution, expected_states = nil, validate_run_id: false, validate_namespace: true) # rubocop:disable Naming/PredicateMethod,Metrics/CyclomaticComplexity,Layout/LineLength,Metrics/PerceivedComplexity
      # check that workflow_execution exists
      return false unless workflow_execution

      # check that workflow_execution has namespace
      return false if validate_namespace && (!workflow_execution.namespace || workflow_execution.namespace.deleted?)

      # check that the state is in expected states
      return false if expected_states&.exclude?(workflow_execution.state.to_sym)

      # check that run_id is on workflow_execution if expected state should have run_id at this point
      return false if validate_run_id && !workflow_execution.run_id

      true
    end

    def update_state(state, run_id: nil, cleaned_value: nil)
      return if @workflow_execution.state.to_sym == state

      @workflow_execution.run_id = run_id unless run_id.nil?
      @workflow_execution.cleaned = cleaned_value unless cleaned_value.nil?

      @workflow_execution.state = state
      @workflow_execution.save
    end
  end
end
