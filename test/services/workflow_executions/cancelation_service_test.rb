# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class CancelationServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_canceling)
    end

    test 'cancel canceling workflow_execution returns true' do
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

      assert WorkflowExecutions::CancelationService.new(@workflow_execution, @user, {}, conn).execute
    end

    test 'cancel non canceling workflow_execution returns false' do
      @workflow_execution = workflow_executions(:irida_next_example)

      assert_not_equal 'canceling', @workflow_execution.state

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

      assert_not WorkflowExecutions::CancelationService.new(@workflow_execution, @user, {}, conn).execute
    end
  end
end
