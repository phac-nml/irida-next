# frozen_string_literal: true

require 'test_helper'

class IntegrationSapporo < ActiveSupport::TestCase
  def setup
    # @user = users(:john_doe)
    # @project = projects(:project1)
    @workflow_execution = workflow_executions(:irida_next_example_end_to_end)
  end

  test 'integration sapporo end to end' do
    assert_equal 'initial', @workflow_execution.state
    assert_not @workflow_execution.cleaned?

    WorkflowExecutionPreparationJob.perform_later(@workflow_execution)
    perform_enqueued_jobs_sequentially(delay_seconds: 5)

    # TODO: add some except_class/only_class filters and test various steps of the workflow execution lifespan
    # perform_enqueued_jobs_sequentially(delay_seconds: 5, except_class: WorkflowExecutionCleanupJob)

    assert_equal 'completed', @workflow_execution.reload.state
    assert @workflow_execution.cleaned?
  end

  private

  # Jobs that are retried must be run one at a time with a short delay to prevent stack errors
  # Allows use of only/except to exit early like perform_enqueued_jobs does
  def perform_enqueued_jobs_sequentially(delay_seconds: 1, only: nil, except: nil) # rubocop:disable Metrics/AbcSize
    class_filter = lambda { |job_class|
      (only.nil? || job_class == only.name) &&
        (except.nil? || job_class != except.name)
    }

    while enqueued_jobs.count >= 1 && class_filter.call(enqueued_jobs.first['job_class'])
      perform_enqueued_jobs(
        only: ->(job) { job['job_id'] == enqueued_jobs.first['job_id'] }
      )
      sleep(delay_seconds)
    end
  end
end

