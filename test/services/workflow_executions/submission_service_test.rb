# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_prepared)
    end

    test 'submit workflow_execution with valid params' do
      assert 'prepared', @workflow_execution.state

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

      WorkflowExecutions::SubmissionService.new(@workflow_execution, conn, @user, {}).execute

      assert_equal 'abc123', @workflow_execution.run_id

      assert_equal 'submitted', @workflow_execution.state
    end
  end
end
