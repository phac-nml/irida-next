# frozen_string_literal: true

require 'test_helper'

module AutomatedWorkflowExecutions
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)
    end

    test 'destroy automated workflow execution with correct permissions' do
      assert_difference -> { AutomatedWorkflowExecution.count } => -1 do
        AutomatedWorkflowExecutions::DestroyService.new(@automated_workflow_execution, @user).execute
      end
    end

    test 'destroy automated workflow execution with incorrect permissions' do
      exception = assert_raises(ActionPolicy::Unauthorized) do
        AutomatedWorkflowExecutions::DestroyService.new(@automated_workflow_execution, users(:michelle_doe)).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :destroy_automated_workflow_executions?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.destroy_automated_workflow_executions?',
                          name: @automated_workflow_execution.namespace.name),
                   exception.result.message
    end
  end
end
