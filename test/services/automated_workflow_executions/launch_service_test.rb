# frozen_string_literal: true

require 'test_helper'

module AutomatedWorkflowExecutions
  class LaunchServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:jeff_doe)
      @automated_workflow_execution = automated_workflow_executions(:projectA_automated_workflow_execution)
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
  end
end
