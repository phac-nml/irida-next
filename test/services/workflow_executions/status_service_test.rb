# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class StatusServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_prepared)
    end

    test 'get status of workflow execution which has completed' do
      run_id = 'status_test_1'
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post('/runs') do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      assert WorkflowExecutions::SubmissionService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal run_id, @workflow_execution.run_id

      assert_equal 'submitted', @workflow_execution.state

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{run_id}/status") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id:, state: 'COMPLETE' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      @workflow_execution = WorkflowExecutions::StatusService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'completing', @workflow_execution.state
    end

    test 'get status of workflow execution which has been canceled' do
      run_id = 'status_test_2'
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post('/runs') do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      assert WorkflowExecutions::SubmissionService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal run_id, @workflow_execution.run_id

      assert_equal 'submitted', @workflow_execution.state

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{run_id}/status") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id:, state: 'CANCELED' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      @workflow_execution = WorkflowExecutions::StatusService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'canceled', @workflow_execution.state
    end

    test 'get status of workflow execution which has errored' do
      run_id = 'status_test_3'
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post('/runs') do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      assert WorkflowExecutions::SubmissionService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal run_id, @workflow_execution.run_id

      assert_equal 'submitted', @workflow_execution.state

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{run_id}/status") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id:, state: 'SYSTEM_ERROR' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      @workflow_execution = WorkflowExecutions::StatusService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'error', @workflow_execution.state
    end
  end
end
