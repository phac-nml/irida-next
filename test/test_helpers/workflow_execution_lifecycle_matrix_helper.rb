# frozen_string_literal: true

module WorkflowExecutionLifecycleMatrixHelper
  def assert_cancel_state_transitions(cancel_path:, scenarios:, locale: I18n.locale)
    scenarios.each do |scenario|
      workflow_execution = workflow_executions(scenario.fetch(:fixture))
      from_state = scenario.fetch(:from_state)

      assert workflow_execution.public_send("#{from_state}?")

      put cancel_path.call(workflow_execution), as: :turbo_stream

      expected_state = scenario[:expected_state]
      if expected_state.present?
        assert_workflow_execution_cancel_success(workflow_execution, expected_state:, locale:)
      else
        assert_response scenario.fetch(:response)
        assert_equal from_state.to_s, workflow_execution.reload.state
      end
    end
  end

  def assert_destroy_state_transitions(destroy_path:, scenarios:)
    scenarios.each do |scenario|
      workflow_execution = workflow_executions(scenario.fetch(:fixture))
      from_state = scenario.fetch(:from_state)

      assert workflow_execution.public_send("#{from_state}?")

      assert_difference -> { WorkflowExecution.count } => scenario.fetch(:workflow_count_delta),
                        -> { SamplesWorkflowExecution.count } => scenario.fetch(:samples_count_delta) do
        delete destroy_path.call(workflow_execution), as: :turbo_stream
      end

      assert_response scenario.fetch(:response)

      assert_scenario_redirect(scenario)
    end
  end

  private

  def assert_scenario_redirect(scenario)
    return if scenario[:redirect_to].blank?

    assert_redirected_to resolve_redirect_target(scenario[:redirect_to])
  end

  def resolve_redirect_target(target)
    target.respond_to?(:call) ? instance_exec(&target) : target
  end
end
