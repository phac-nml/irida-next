# frozen_string_literal: true

require 'test_helper'

module AutomatedWorkflowExecutions
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @automated_workflow_execution = automated_workflow_executions(:valid_automated_workflow_execution)
    end

    test 'update automated workflow execution with valid params' do
      valid_params = { workflow_params: { assembler: 'experimental' } }

      assert_changes -> { @automated_workflow_execution.workflow_params['assembler'] }, to: 'experimental' do
        AutomatedWorkflowExecutions::UpdateService.new(@automated_workflow_execution, @user, valid_params).execute
      end
    end

    test 'update automated workflow execution with invalid params' do
      invalid_params = { metadata: {} }

      assert_no_changes -> { @automated_workflow_execution } do
        AutomatedWorkflowExecutions::UpdateService.new(@automated_workflow_execution, @user, invalid_params).execute
      end

      assert_includes @automated_workflow_execution.errors[:metadata],
                      'root is missing required keys: workflow_name, workflow_version'
    end

    test 'update automated workflow execution with incorrect permissions' do
      valid_params = { workflow_params: { assembler: 'experimental' } }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        AutomatedWorkflowExecutions::UpdateService.new(@automated_workflow_execution, users(:michelle_doe),
                                                       valid_params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :update_automated_workflow_executions?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.update_automated_workflow_executions?',
                          name: @automated_workflow_execution.namespace.name),
                   exception.result.message
    end
  end
end
