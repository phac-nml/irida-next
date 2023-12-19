# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_prepared)
    end

    test 'get status of workflow execution which has completed' do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post('/runs') do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: 'abc123' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      assert WorkflowExecutions::SubmissionService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'abc123', @workflow_execution.run_id

      assert_equal 'submitted', @workflow_execution.state

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get('/runs/abc123/status') do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: 'abc123', state: 'COMPLETE' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      @workflow_execution = WorkflowExecutions::StatusService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'completed', @workflow_execution.state
    end

    test 'get status of workflow execution which has been canceled' do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post('/runs') do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: 'abc123' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      assert WorkflowExecutions::SubmissionService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'abc123', @workflow_execution.run_id

      assert_equal 'submitted', @workflow_execution.state

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get('/runs/abc123/status') do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: 'abc123', state: 'CANCELED' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      @workflow_execution = WorkflowExecutions::StatusService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'canceled', @workflow_execution.state
    end

    test 'get status of workflow execution which has errored' do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post('/runs') do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: 'abc123' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      assert WorkflowExecutions::SubmissionService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'abc123', @workflow_execution.run_id

      assert_equal 'submitted', @workflow_execution.state

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get('/runs/abc123/status') do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: 'abc123', state: 'SYSTEM_ERROR' }
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
