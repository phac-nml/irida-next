# frozen_string_literal: true

require 'test_helper'

module AutomatedWorkflowExecutions
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
      @project_namespace = @project.namespace
    end

    test 'create automated workflow execution with valid params and authorized namespace' do
      valid_params = {
        namespace: @project_namespace,
        metadata: { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params: { assembler: 'stub' },
        email_notification: true,
        update_samples: true
      }

      assert_difference -> { AutomatedWorkflowExecution.count } => 1 do
        @new_awe = AutomatedWorkflowExecutions::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create automated workflow execution with invalid params and authorized namespace' do
      invalid_params = {
        namespace: @project_namespace,
        metadata: { workflow_name: 'phac-nml/iridanextexample' },
        workflow_params: { assembler: 'stub' },
        email_notification: true,
        update_samples: true
      }

      assert_no_difference -> { AutomatedWorkflowExecution.count } do
        @new_awe = AutomatedWorkflowExecutions::CreateService.new(@user, invalid_params).execute
      end

      assert_includes @new_awe.errors[:metadata], 'object at root is missing required properties: workflow_version'
    end

    test 'create automated workflow execution with valid params but unauthorized namespace' do
      valid_params = {
        namespace: @project_namespace,
        metadata: { workflow_name: 'phac-nml/iridanextexample', workflow_version: '1.0.2' },
        workflow_params: { assembler: 'stub' },
        email_notification: true,
        update_samples: true
      }

      exception = assert_raises(ActionPolicy::Unauthorized) do
        @new_awe = AutomatedWorkflowExecutions::CreateService.new(users(:michelle_doe), valid_params).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :create_automated_workflow_executions?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.create_automated_workflow_executions?',
                          name: @project_namespace.name),
                   exception.result.message
    end
  end
end
