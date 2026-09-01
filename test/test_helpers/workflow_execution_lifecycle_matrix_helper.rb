# frozen_string_literal: true

module WorkflowExecutionLifecycleMatrixHelper
  CANCEL_OUTCOMES = {
    'initial' => { expected_state: 'canceled' },
    'prepared' => { expected_state: 'canceled' },
    'submitted' => { expected_state: 'canceling' },
    'running' => { expected_state: 'canceling' },
    'completed' => { response: :unprocessable_content }
  }.freeze

  DESTROY_BLOCKED = { workflow_count_delta: 0, samples_count_delta: 0, response: :unprocessable_content }.freeze
  DESTROY_ALLOWED = { workflow_count_delta: -1, samples_count_delta: -1, response: :redirect }.freeze
  DESTROY_OUTCOMES = {
    'initial' => DESTROY_BLOCKED,
    'prepared' => DESTROY_BLOCKED,
    'submitted' => DESTROY_BLOCKED,
    'running' => DESTROY_BLOCKED,
    'canceling' => DESTROY_BLOCKED,
    'completed' => DESTROY_ALLOWED,
    'error' => DESTROY_ALLOWED,
    'canceled' => DESTROY_ALLOWED
  }.freeze

  def assert_cancel_state_transitions(cancel_path:, fixtures:, locale: I18n.locale)
    fixtures.each do |fixture|
      workflow_execution = workflow_executions(fixture)
      from_state = workflow_execution.state
      outcome = CANCEL_OUTCOMES.fetch(from_state)

      put cancel_path.call(workflow_execution), as: :turbo_stream

      expected_state = outcome[:expected_state]
      if expected_state.present?
        assert_workflow_execution_cancel_success(workflow_execution, expected_state:, locale:)
      else
        assert_response outcome.fetch(:response)
        assert_equal from_state, workflow_execution.reload.state
      end
    end
  end

  def assert_destroy_state_transitions(destroy_path:, fixtures:, redirect_to: nil)
    fixtures.each do |fixture|
      workflow_execution = workflow_executions(fixture)
      outcome = DESTROY_OUTCOMES.fetch(workflow_execution.state)

      assert_difference -> { WorkflowExecution.count } => outcome.fetch(:workflow_count_delta),
                        -> { SamplesWorkflowExecution.count } => outcome.fetch(:samples_count_delta) do
        delete destroy_path.call(workflow_execution), as: :turbo_stream
      end

      assert_response outcome.fetch(:response)
      assert_redirected_to resolve_redirect_target(redirect_to) if outcome[:response] == :redirect
    end
  end

  private

  def resolve_redirect_target(target)
    target.respond_to?(:call) ? instance_exec(&target) : target
  end
end
