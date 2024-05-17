# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class EndToEndTest < ActiveSupport::TestCase
    def setup
      # @user = users(:john_doe)
      # @project = projects(:project1)
      @workflow_execution = workflow_executions(:irida_next_example_end_to_end)
    end

    test 'test end to end sapporo integration' do
      assert_equal 'initial', @workflow_execution.state

      WorkflowExecutionPreparationJob.perform_later(@workflow_execution)
      perform_enqueued_jobs_sequentially(delay_seconds: 5, except_class: WorkflowExecutionCleanupJob)
      assert_equal 'completed', @workflow_execution.reload.state
      # TODO: cleanup step
    end

    private

    # jobs that are retried must be run one at a time with a short delay to prevent stack errors
    # This functions the same as `perform_enqueued_jobs(only: MyJob, except: MyJob)` but one at a time
    def perform_enqueued_jobs_sequentially(delay_seconds: 1, only_class: nil, except_class: nil) # rubocop:disable Metrics/AbcSize
      # Allows while to continue only if class passes filters
      # only_class allows only that class to be run, breaking when next job is not of that class
      # except_class allows any class but that to be run, breaking when next job is of that class
      class_filter = lambda { |job_class|
        return (only_class.nil? || job_class == only_class.name) &&
               (except_class.nil? || job_class != except_class.name)
      }

      while enqueued_jobs.count >= 1 && class_filter.call(enqueued_jobs.first['job_class'])
        perform_enqueued_jobs(
          only: ->(job) { job['job_id'] == enqueued_jobs.first['job_id'] }
        )
        sleep(delay_seconds)
      end
    end
  end
end
