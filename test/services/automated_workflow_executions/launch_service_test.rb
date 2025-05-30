# frozen_string_literal: true

require 'test_helper'

module AutomatedWorkflowExecutions
  class LaunchServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:jeff_doe)
      @automated_workflow_execution = automated_workflow_executions(:projectA_automated_workflow_execution_one)
      @sample = samples(:sampleB)
      @automation_bot = users(:projectA_automation_bot)
      @pe_attachment_pair = { 'forward' => attachments(:attachmentPEFWD1), 'reverse' => attachments(:attachmentPEREV1) }
    end

    test 'creates workflow execution with valid arguments' do
      assert_difference -> { WorkflowExecution.count } => 1 do
        AutomatedWorkflowExecutions::LaunchService.new(@automated_workflow_execution, @sample, @pe_attachment_pair,
                                                       @automation_bot).execute
      end
    end

    test 'returns false if workflow is not valid' do
      assert_no_difference -> { WorkflowExecution.count } do
        ret_val = AutomatedWorkflowExecutions::LaunchService.new(
          automated_workflow_executions(:projectA_invalid_automated_workflow_execution), @sample, @pe_attachment_pair,
          @automation_bot
        ).execute

        assert ret_val == false
      end
    end

    test 'doesn\'t create workflow execution with invalid project bot' do
      exception = assert_raises(ActionPolicy::Unauthorized) do
        AutomatedWorkflowExecutions::LaunchService.new(@automated_workflow_execution, @sample, @pe_attachment_pair,
                                                       users(:project1_automation_bot)).execute
      end

      assert_equal Namespaces::ProjectNamespacePolicy, exception.policy
      assert_equal :submit_workflow?, exception.rule
      assert exception.result.reasons.is_a?(::ActionPolicy::Policy::FailureReasons)
      assert_equal I18n.t(:'action_policy.policy.namespaces/project_namespace.submit_workflow?',
                          name: @sample.project.name, namespace_type: @sample.project.namespace.type),
                   exception.result.message
    end

    test 'sets the name in the created workflow execution to samples puid if automated workflow execution doesn\'t have a name' do # rubocop:disable Layout/LineLength
      workflow_execution = AutomatedWorkflowExecutions::LaunchService.new(@automated_workflow_execution, @sample,
                                                                          @pe_attachment_pair,
                                                                          @automation_bot).execute
      assert_equal "#{@sample.name} (#{@sample.puid})", workflow_execution.name
    end

    test 'sets the name in the created workflow execution to automated workflow execution name plus samples puid if automated workflow execution has a name' do # rubocop:disable Layout/LineLength
      @automated_workflow_execution.name = 'Prefix'
      workflow_execution = AutomatedWorkflowExecutions::LaunchService.new(@automated_workflow_execution, @sample,
                                                                          @pe_attachment_pair,
                                                                          @automation_bot).execute
      assert_equal "Prefix #{@sample.name} (#{@sample.puid})", workflow_execution.name
    end
  end
end
