# frozen_string_literal: true

require 'test_helper'

class UnattachedBlobsCleanupJobTest < ActiveJob::TestCase
  def setup
    # Go back in time to ignore other unattached blobs created during test setup
    travel_to 100.days.ago
  end

  def make_unattached_blob
    ActiveStorage::Blob.create_before_direct_upload!(
      filename: 'missing.file', byte_size: 404, checksum: 'Y33CgI35hFoI6p+WBXYl+A=='
    )
  end

  test 'valid blobs are unattached pretest' do
    blob1 = make_unattached_blob
    blob2 = make_unattached_blob
    blob3 = make_unattached_blob
    travel 2.days
    assert blob1.valid?
    assert blob2.valid?
    assert blob3.valid?
    assert_equal 3, ActiveStorage::Blob.unattached.where(created_at: ..(Date.yesterday.midnight - 1)).count
  end

  test 'deletion after default 1 day' do
    blob1 = make_unattached_blob

    # go forward 2 days
    travel 2.days
    blob2 = make_unattached_blob

    # go forward 1 day
    travel 1.day
    blob3 = make_unattached_blob

    # run job and verify blob count changes
    assert_difference -> { ActiveStorage::Blob.unattached.count } => -1,
                      -> { ActiveStorage::Blob.count } => -1 do
      UnattachedBlobsCleanupJob.perform_now
      perform_enqueued_jobs # to run purge_later
    end

    # verify attachment exist or not
    id_list = ActiveStorage::Blob.unattached.where(created_at: ..(Date.tomorrow)).map(&:id)
    assert_not(id_list.include?(blob1.id))
    assert(id_list.include?(blob2.id))
    assert(id_list.include?(blob3.id))
  end

  test 'deletion after specified 14 days' do
    blob1 = make_unattached_blob

    # go forward 2 days
    travel 2.days
    blob2 = make_unattached_blob

    # go forward 1 day
    travel 15.days
    blob3 = make_unattached_blob

    # run job and verify blob count changes
    assert_difference -> { ActiveStorage::Blob.unattached.count } => -1,
                      -> { ActiveStorage::Blob.count } => -1 do
      UnattachedBlobsCleanupJob.perform_now(days_old: 14)
      perform_enqueued_jobs # to run purge_later
    end

    # verify attachment exist or not
    id_list = ActiveStorage::Blob.unattached.where(created_at: ..(Date.tomorrow)).map(&:id)
    assert_not(id_list.include?(blob1.id))
    assert(id_list.include?(blob2.id))
    assert(id_list.include?(blob3.id))
  end

  test 'deletion multiple' do
    blob1 = make_unattached_blob

    # go forward 2 days
    travel 2.days
    blob2 = make_unattached_blob

    # go forward 1 day
    travel 5.days
    blob3 = make_unattached_blob

    # run job and verify blob count changes
    assert_difference -> { ActiveStorage::Blob.unattached.count } => -2,
                      -> { ActiveStorage::Blob.count } => -2 do
      UnattachedBlobsCleanupJob.perform_now
      perform_enqueued_jobs # to run purge_later
    end

    # verify attachment exist or not
    id_list = ActiveStorage::Blob.unattached.where(created_at: ..(Date.tomorrow)).map(&:id)
    assert_not(id_list.include?(blob1.id))
    assert_not(id_list.include?(blob2.id))
    assert(id_list.include?(blob3.id))
  end

  test 'invalid argument string' do
    assert_raise(Exception) do
      UnattachedBlobsCleanupJob.perform_now(days_old: 'this is not a number')
    end
  end

  test 'invalid argument negative' do
    assert_raise(Exception) do
      UnattachedBlobsCleanupJob.perform_now(days_old: -1)
    end
  end

  test 'invalid argument zero' do
    assert_raise(Exception) do
      UnattachedBlobsCleanupJob.perform_now(days_old: 0)
    end
  end

  test 'invalid argument int as string' do
    assert_raise(Exception) do
      UnattachedBlobsCleanupJob.perform_now(days_old: '1')
    end
  end
end
