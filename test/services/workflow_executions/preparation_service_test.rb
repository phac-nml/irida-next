# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class PreparationServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example)
    end

    test 'prepare workflow_execution with valid params' do
      assert @workflow_execution.initial?

      assert_difference -> { ActiveStorage::Attachment.count } => 2 do
        WorkflowExecutions::PreparationService.new(@workflow_execution, @user, {}).execute
      end

      assert_equal 1, @workflow_execution.inputs.size
      assert_equal 1, @workflow_execution.samples_workflow_executions.first.inputs.size

      assert @workflow_execution.workflow_params.key? 'input'
      assert @workflow_execution.workflow_params.key? 'outdir'
      assert_match @workflow_execution.inputs.first.blob.key, @workflow_execution.workflow_params['input']
      assert @workflow_execution.workflow_params['outdir'].ends_with?('/')
      assert @workflow_execution.blob_run_directory

      assert_equal 'prepared', @workflow_execution.state
    end
  end
end
