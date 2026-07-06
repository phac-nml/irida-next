# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class CleanupServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @completed_workflow_execution = workflow_executions(:irida_next_example_completed_unclean)
      @error_workflow_execution = workflow_executions(:irida_next_example_error_unclean)
      @running_workflow_execution = workflow_executions(:irida_next_example_running)
    end

    test 'returns run log and stdout for completed workflow execution' do
      run_id = @completed_workflow_execution.run_id
      expected_run_log = { run_id:, state: 'COMPLETE' }
      expected_run_stdout = 'Workflow execution output'

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{run_id}") do
        [
          200,
          { 'Content-Type': 'application/json' },
          expected_run_log
        ]
      end
      stubs.get("/runs/#{run_id}/stdout") do
        [
          200,
          { 'Content-Type': 'text/plain' },
          expected_run_stdout
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      result = WorkflowExecutions::CleanupService.new(@completed_workflow_execution, @user, {}, conn).execute

      assert_equal expected_run_log, result[:run_log]
      assert_equal expected_run_stdout, result[:run_stdout]
    end

    test 'returns run log and stdout for error workflow execution' do
      run_id = @error_workflow_execution.run_id
      expected_run_log = { run_id:, state: 'SYSTEM_ERROR' }
      expected_run_stdout = 'Workflow execution output from failed run'

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{run_id}") do
        [
          200,
          { 'Content-Type': 'application/json' },
          expected_run_log
        ]
      end
      stubs.get("/runs/#{run_id}/stdout") do
        [
          200,
          { 'Content-Type': 'text/plain' },
          expected_run_stdout
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      result = WorkflowExecutions::CleanupService.new(@error_workflow_execution, @user, {}, conn).execute

      assert_equal expected_run_log, result[:run_log]
      assert_equal expected_run_stdout, result[:run_stdout]
    end

    test 'returns nil values for non terminal workflow execution state' do
      stubs = Faraday::Adapter::Test::Stubs.new

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      result = WorkflowExecutions::CleanupService.new(@running_workflow_execution, @user, {}, conn).execute

      assert_equal({ run_log: nil, run_stdout: nil }, result)
    end
  end
end
