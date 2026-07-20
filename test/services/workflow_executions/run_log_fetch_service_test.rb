# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class RunLogFetchServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @completed_workflow_execution = workflow_executions(:irida_next_example_completed_unclean)
      @error_workflow_execution = workflow_executions(:irida_next_example_error_unclean)
      @running_workflow_execution = workflow_executions(:irida_next_example_running)
    end

    test 'returns stdout and stderr for completed workflow execution' do
      run_id = @completed_workflow_execution.run_id
      expected_stdout = 'Workflow execution output'
      expected_stderr = 'Workflow execution stderr'

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{run_id}") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: run_id, state: 'COMPLETE',
            run_log: { stdout: "/runs/#{run_id}/stdout", stderr: "/runs/#{run_id}/stderr" } }
        ]
      end
      stubs.get("/runs/#{run_id}/stdout") do
        [
          200,
          { 'Content-Type': 'text/plain' },
          expected_stdout
        ]
      end
      stubs.get("/runs/#{run_id}/stderr") do
        [
          200,
          { 'Content-Type': 'text/plain' },
          expected_stderr
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      result = WorkflowExecutions::RunLogFetchService.new(@completed_workflow_execution, @user, {}, conn).execute

      assert_equal expected_stdout, result[:stdout]
      assert_equal expected_stderr, result[:stderr]
    end

    test 'returns stdout and stderr for error workflow execution' do
      run_id = @error_workflow_execution.run_id
      expected_stdout = 'Workflow execution output from failed run'
      expected_stderr = 'Workflow execution stderr from failed run'

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{run_id}") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: run_id, state: 'EXECUTOR_ERROR',
            run_log: { stdout: "/runs/#{run_id}/stdout", stderr: "/runs/#{run_id}/stderr" } }
        ]
      end
      stubs.get("/runs/#{run_id}/stdout") do
        [
          200,
          { 'Content-Type': 'text/plain' },
          expected_stdout
        ]
      end
      stubs.get("/runs/#{run_id}/stderr") do
        [
          200,
          { 'Content-Type': 'text/plain' },
          expected_stderr
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      result = WorkflowExecutions::RunLogFetchService.new(@error_workflow_execution, @user, {}, conn).execute

      assert_equal expected_stdout, result[:stdout]
      assert_equal expected_stderr, result[:stderr]
    end

    test 'falls back to run log values when stream endpoints are unavailable' do
      run_id = @completed_workflow_execution.run_id

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{run_id}") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: run_id, state: 'COMPLETE',
            run_log: { stdout: "/runs/#{run_id}/stdout", stderr: "/runs/#{run_id}/stderr" } }
        ]
      end
      stubs.get("/runs/#{run_id}/stdout") do
        raise Faraday::ResourceNotFound, 'stdout endpoint unavailable'
      end
      stubs.get("/runs/#{run_id}/stderr") do
        raise Faraday::ResourceNotFound, 'stderr endpoint unavailable'
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      result = WorkflowExecutions::RunLogFetchService.new(@completed_workflow_execution, @user, {}, conn).execute

      assert_nil result[:stdout]
      assert_nil result[:stderr]
    end

    test 'returns nil values for non terminal workflow execution state' do
      stubs = Faraday::Adapter::Test::Stubs.new

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      result = WorkflowExecutions::RunLogFetchService.new(@running_workflow_execution, @user, {}, conn).execute

      assert_equal({ stdout: nil, stderr: nil }, result)
    end
  end
end
