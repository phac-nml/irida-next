# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class CancellationServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_submitted)
    end

    test 'cancel submitted workflow_execution' do
      assert 'submitted', @workflow_execution.state

      run_id = 'cancel123'

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post("/runs/#{run_id}/cancel") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      assert WorkflowExecutions::CancellationService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal run_id, @workflow_execution.run_id

      assert_equal 'cancelled', @workflow_execution.state
    end

    test 'cancel unsubmitted workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example)

      assert_not_equal 'submitted', @workflow_execution.state

      # no run_id on WorkflowExecution, so .cancel_job will be run with nil
      run_id = nil

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post("/runs/#{run_id}/cancel") do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      assert_not WorkflowExecutions::CancellationService.new(@workflow_execution, conn, @user, {}).execute

      assert_nil @workflow_execution.run_id

      assert_not_equal 'submitted', @workflow_execution.state
      assert_not_equal 'cancelled', @workflow_execution.state
    end
  end
end
