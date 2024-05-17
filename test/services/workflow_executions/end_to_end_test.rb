# frozen_string_literal: true

require 'test_helper'

module WorkflowExecutions
  class EndToEndTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
    end

    test 'test create new workflow execution' do
      @workflow_execution = workflow_executions(:irida_next_example_end_to_end)

      assert_equal 'initial', @workflow_execution.reload.state

      WorkflowExecutionPreparationJob.perform_later(@workflow_execution)
      perform_enqueued_jobs_with_delay(5, except_class: WorkflowExecutionCleanupJob)
      assert_equal 'completed', @workflow_execution.reload.state
      # TODO: cleanup step
    end

    def perform_enqueued_jobs_with_delay(delay_seconds, except_class:)
      while enqueued_jobs.count >= 1 && enqueued_jobs.first['job_class'] != except_class.name
        # run a single queued job
        currently_queued_job = enqueued_jobs.first
        puts "RUNNING: #{currently_queued_job['job_class']}"
        perform_enqueued_jobs(only: ->(job) { job['job_id'] == currently_queued_job['job_id'] })
        # wait for sapporo before continuing, prevents heap error when jobs run immediately
        sleep(delay_seconds)
      end
    end
  end
end
