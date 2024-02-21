# frozen_string_literal: true

require 'test_helper'

class SamplesCleanupJobTest < ActiveJob::TestCase
  def setup
    @sample1 = samples(:sample1)
    @sample2 = samples(:sample2)
    @sample3 = samples(:sample3)
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
    travel 4.days
    assert_nil @sample2.deleted_at
    @sample2.destroy
    assert_not_nil @sample2.deleted_at
    travel 5.days
    assert_nil @sample3.deleted_at

    assert_difference -> { Sample.only_deleted.count } => -1 do
      SamplesCleanupJob.perform_now
    end

    assert_not(Sample.exists?(@sample1.id))
    assert(Sample.only_deleted.where(id: @sample2.id))
    assert(Sample.exists?(@sample3.id))
  end

  test 'deletion after 8 days' do
    assert_nil @sample1.deleted_at
    @sample1.destroy
    assert_not_nil @sample1.deleted_at
    travel 4.days
    assert_nil @sample2.deleted_at
    @sample2.destroy
    assert_not_nil @sample2.deleted_at
    travel 5.days
    assert_nil @sample3.deleted_at

    assert_difference -> { Sample.only_deleted.count } => -1 do
      SamplesCleanupJob.perform_now(days_old: 8)
    end

    assert_not(Sample.exists?(@sample1.id))
    assert(Sample.only_deleted.where(id: @sample2.id))
    assert(Sample.exists?(@sample3.id))
  end
end
