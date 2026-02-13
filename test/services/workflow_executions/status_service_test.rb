# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class StatusServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @run_id = 'test_run_id'
      @workflow_execution = workflow_executions(:irida_next_example_submitted)
      @workflow_execution.run_id = @run_id
      @workflow_execution.save
    end

    test 'get status of workflow execution which has completed' do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{@run_id}/status") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: @run_id, state: 'COMPLETE' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      status = WorkflowExecutions::StatusService.new(@workflow_execution, @user, {}, conn).execute

      assert_equal :completing, status
    end

    test 'get status of workflow execution which is running' do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{@run_id}/status") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: @run_id, state: 'RUNNING' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      status = WorkflowExecutions::StatusService.new(@workflow_execution, @user, {}, conn).execute

      assert_equal :running, status
    end

    test 'get status of workflow execution which is queued' do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{@run_id}/status") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: @run_id, state: 'QUEUED' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      status = WorkflowExecutions::StatusService.new(@workflow_execution, @user, {}, conn).execute

      assert_equal :submitted, status
    end

    test 'get status of workflow execution which has been canceled' do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{@run_id}/status") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: @run_id, state: 'CANCELED' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      status = WorkflowExecutions::StatusService.new(@workflow_execution, @user, {}, conn).execute

      assert_equal :canceled, status
    end

    test 'get status of workflow execution which has errored' do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{@run_id}/status") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: @run_id, state: 'SYSTEM_ERROR' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      status = WorkflowExecutions::StatusService.new(@workflow_execution, @user, {}, conn).execute

      assert_equal :error, status
    end

    test 'get status of automated workflow execution which has errored' do
      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.get("/runs/#{@run_id}/status") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: @run_id, state: 'SYSTEM_ERROR' }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      status = WorkflowExecutions::StatusService.new(@workflow_execution, @user, {}, conn).execute

      assert_equal :error, status
    end
  end
end
