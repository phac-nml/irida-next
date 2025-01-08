# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_new)
    end

    test 'submitter can update name of workflow execution post launch' do
      valid_params = { name: 'New Name' }

      assert_changes -> { @workflow_execution.name }, to: 'New Name' do
        WorkflowExecutions::UpdateService.new(@workflow_execution, @user, valid_params).execute
      end
    end

    test 'user cannot update workflow execution name for another user\'s personal workflow execution' do
      valid_params = { name: 'New Name' }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        WorkflowExecutions::UpdateService.new(@workflow_execution, users(:michelle_doe), valid_params).execute
      end

      assert_equal WorkflowExecutionPolicy, exception.policy
      assert_equal :update?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.workflow_execution.update?',
                          id: @workflow_execution.id),
                   exception.result.message
    end

    test 'analyst or higher can update workflow execution name for automated workflow execution' do
      workflow_execution = workflow_executions(:automated_workflow_execution)
      valid_params = { name: 'New Name Automated' }

      assert_changes -> { workflow_execution.name }, to: 'New Name Automated' do
        WorkflowExecutions::UpdateService.new(workflow_execution, users(:james_doe), valid_params).execute
      end
    end

    test 'access level below analyst cannot update workflow execution name for automated workflow execution' do
      workflow_execution = workflow_executions(:automated_workflow_execution)
      valid_params = { name: 'New Name' }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        WorkflowExecutions::UpdateService.new(workflow_execution, users(:ryan_doe), valid_params).execute
      end

      assert_equal WorkflowExecutionPolicy, exception.policy
      assert_equal :update?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.workflow_execution.update?',
                          id: workflow_execution.id),
                   exception.result.message
    end
  end
end
