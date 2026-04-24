# frozen_string_literal: true

require 'test_helper'

class SamplesCleanupJobTest < ActiveJob::TestCase
  def setup
    @sample1 = samples(:sample1)
  end

  test 'invalid argument string' do
    assert_raise(Exception) do
      SamplesCleanupJob.perform_now(days_old: '1')
    end
  end

  test 'invalid argument negative' do
    assert_raise(Exception) do
      SamplesCleanupJob.perform_now(days_old: -1)
    end
  end

  test 'invalid argument zero' do
    assert_raise(Exception) do
      SamplesCleanupJob.perform_now(days_old: 0)
    end
  end

  test 'deletion after default 7 days' do
    assert_nil @sample1.deleted_at
    @sample1.destroy
    assert_not_nil @sample1.deleted_at

    travel 9.days

    assert_difference -> { Sample.only.count } => -1,
                      -> { Sample.only_deleted.count } => -1,
                      -> { Attachment.only_deleted.count } => -2,
                      -> { ActiveStorage::Attachment.count } => -2,
                      -> { SamplesWorkflowExecution.only_deleted.count } => 0,
                      -> { WorkflowExecution.only_deleted.count } => 0 do
      SamplesCleanupJob.perform_now
    end
  end

  test 'deletion after specified 4 days' do
    assert_nil @sample1.deleted_at
    @sample1.destroy
    assert_not_nil @sample1.deleted_at

    travel 6.days

    assert_difference -> { Sample.only.count } => -1,
                      -> { Sample.only_deleted.count } => -1,
                      -> { Attachment.only_deleted.count } => -2,
                      -> { ActiveStorage::Attachment.count } => -2,
                      -> { SamplesWorkflowExecution.only_deleted.count } => 0,
                      -> { WorkflowExecution.only_deleted.count } => 0 do
      SamplesCleanupJob.perform_now(days_old: 4)
    end
  end

  test 'deleting a sample also nullifies associated samples_workflow_executions' do
    workflow_execution = workflow_executions(:workflow_execution_valid)
    sample_workflow_execution = samples_workflow_executions(:samples_workflow_executions_valid)

    # Ensure the association exists before deletion
    assert_includes workflow_execution.samples_workflow_executions, sample_workflow_execution

    # Delete the workflow execution
    workflow_execution.destroy

    @sample1.update(deleted_at: 12.days.ago)

    SamplesCleanupJob.perform_now

    # Reload the sample_workflow_execution and check if it has been deleted
    sample_id = sample_workflow_execution.reload.sample_id
    assert_nil sample_id, 'Associated SamplesWorkflowExecution should be deleted when WorkflowExecution is destroyed'
  end

  test 'no turbo stream broadcasts to project if project is deleted' do
    project = projects(:project1)
    sample = samples(:sample1)

    assert_not project.deleted?
    assert_not sample.project.deleted?

    assert_no_enqueued_jobs(only: Turbo::Streams::BroadcastStreamJob) do
      project.destroy!
      perform_enqueued_jobs
    end

    SamplesCleanupJob.perform_now

    assert_no_enqueued_jobs(only: Turbo::Streams::BroadcastStreamJob) do
      perform_enqueued_jobs
    end
  end

  test 'no turbo stream broadcasts to a project namespace parent if parent is deleted' do
    group = groups(:group_one)
    project = projects(:project1)
    sample = samples(:sample1)

    assert_not project.deleted?
    assert_not sample.project.deleted?

    assert_no_enqueued_jobs(only: Turbo::Streams::BroadcastStreamJob) do
      project.destroy!
      group.destroy!
      perform_enqueued_jobs
    end

    SamplesCleanupJob.perform_now

    assert_no_enqueued_jobs(only: Turbo::Streams::BroadcastStreamJob) do
      perform_enqueued_jobs
    end
  end
end
