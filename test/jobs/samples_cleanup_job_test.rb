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
end
