# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class CancelationServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_canceling)
    end

    test 'cancel canceling workflow_execution' do
      assert 'canceling', @workflow_execution.state

      run_id = @workflow_execution.run_id

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

      assert WorkflowExecutions::CancelationService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal run_id, @workflow_execution.run_id

      assert_equal 'canceled', @workflow_execution.state
    end

    test 'cancel non canceling workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example)

      assert_not_equal 'canceling', @workflow_execution.state

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

      assert_not WorkflowExecutions::CancelationService.new(@workflow_execution, conn, @user, {}).execute

      assert_nil @workflow_execution.run_id

      assert_not_equal 'canceling', @workflow_execution.state
      assert_not_equal 'canceled', @workflow_execution.state
    end
  end
end
