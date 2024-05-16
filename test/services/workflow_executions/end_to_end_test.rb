# frozen_string_literal: true

# require 'active_storage_test_case'
require 'test_helper'
# require 'webmock/minitest'

module WorkflowExecutions
  class EndToEndest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
    end

    test 'test create new workflow execution' do
      @workflow_execution = workflow_executions(:irida_next_example_end_to_end)

      assert_equal 'initial', @workflow_execution.reload.state

      assert_performed_jobs 2, except: WorkflowExecutionStatusJob do
        WorkflowExecutionPreparationJob.perform_later(@workflow_execution)
      end

      assert_equal 'prepared', @workflow_execution.reload.state
    end
  end
end
