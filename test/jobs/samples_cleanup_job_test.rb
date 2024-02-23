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

    travel 8.days

    assert_difference -> { Sample.only.count } => -1,
                      -> { Sample.only_deleted.count } => -1,
                      -> { Attachment.only_deleted.count } => -2,
                      -> { ActiveStorage::Attachment.count } => -2,
                      -> { SamplesWorkflowExecution.only_deleted.count } => 0,
                      -> { WorkflowExecution.only_deleted.count } => 0 do
      # Question: I noticed `dependent: :destroy`` is specified for sample attachments,
      # but not samples_workflow_executions and workflow_executions. Is this intentional?
      # If so, should I leave the test assertions that they don't change?
      SamplesCleanupJob.perform_now
    end

    assert_not(Sample.exists?(@sample1.id))
  end

  test 'deletion after specified 4 days' do
    assert_nil @sample1.deleted_at
    @sample1.destroy
    assert_not_nil @sample1.deleted_at

    travel 5.days

    assert_difference -> { Sample.only.count } => -1,
                      -> { Sample.only_deleted.count } => -1,
                      -> { Attachment.only_deleted.count } => -2,
                      -> { ActiveStorage::Attachment.count } => -2,
                      -> { SamplesWorkflowExecution.only_deleted.count } => 0,
                      -> { WorkflowExecution.only_deleted.count } => 0 do
      SamplesCleanupJob.perform_now(days_old: 4)
    end

    assert_not(Sample.exists?(@sample1.id))
  end
end
