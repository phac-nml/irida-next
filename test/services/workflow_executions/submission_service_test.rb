# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class SubmissionServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @workflow_execution = workflow_executions(:irida_next_example_prepared)
    end

    test 'submit prepared workflow_execution' do
      assert 'prepared', @workflow_execution.state
      test_run_id = 'submission_service_test_1'

      stubs = Faraday::Adapter::Test::Stubs.new
      stubs.post('/runs') do
        [
          200,
          { 'Content-Type': 'application/json' },
          { run_id: test_run_id }
        ]
      end

      conn = Faraday.new do |builder|
        builder.adapter :test, stubs
      end

      result = WorkflowExecutions::SubmissionService.new(@workflow_execution, @user, {}, conn).execute

      assert_equal test_run_id, result
    end

    test 'submit unprepared workflow_execution' do
      @workflow_execution = workflow_executions(:irida_next_example)

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

      result = WorkflowExecutions::SubmissionService.new(@workflow_execution, @user, {}, conn).execute

      assert_not result
    end
  end
end
