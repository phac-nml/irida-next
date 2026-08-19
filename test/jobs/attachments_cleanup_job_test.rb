# frozen_string_literal: true

require 'test_helper'

class AttachmentsCleanupJobTest < ActiveJob::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  def setup # rubocop:disable Metrics/MethodLength
    attachable = samples(:sample2)
    @attachment1 = Attachment.create!(
      attachable: attachable,
      file: fixture_file_upload('test_file_A.fastq', 'text/plain'),
      metadata: { 'format' => 'fastq', 'compression' => 'none' }
    )
    @attachment2 = Attachment.create!(
      attachable: attachable,
      file: fixture_file_upload('test_file_B.fastq', 'text/plain'),
      metadata: { 'format' => 'fastq', 'compression' => 'none' }
    )
    @attachment3 = Attachment.create!(
      attachable: attachable,
      file: fixture_file_upload('test_file_C.fastq', 'text/plain'),
      metadata: { 'format' => 'fastq', 'compression' => 'none' }
    )
  end

  test 'valid attachments pretest' do
    assert @attachment1.valid?
    assert @attachment2.valid?
    assert @attachment3.valid?
  end

  test 'deletion after default 7 days' do
    # delete (soft) first attachment
    assert_nil @attachment1.deleted_at
    @attachment1.destroy
    assert_not_nil @attachment1.deleted_at
    # go forward 4 days
    travel 4.days
    # delete (soft) second attachment
    assert_nil @attachment2.deleted_at
    @attachment2.destroy
    assert_not_nil @attachment2.deleted_at
    # go forward 5 more days
    travel 5.days
    # verify files are only soft deleted
    assert_not_nil @attachment1.deleted_at
    assert_not_nil @attachment2.deleted_at
    assert_nil @attachment3.deleted_at

    # run job and verify file/object count changes
    assert_difference -> { ActiveStorage::Attachment.count } => -1,
                      -> { Attachment.only_deleted.count } => -1,
                      -> { Attachment.count } => 0 do
      AttachmentsCleanupJob.perform_now
    end

    # verify attachment exist or not
    id_list = Attachment.all.map(&:id)
    assert_not(id_list.include?(@attachment1.id))
    assert_not(id_list.include?(@attachment2.id))
    assert(Attachment.only_deleted.map(&:id).include?(@attachment2.id))
    assert(id_list.include?(@attachment3.id))
  end

  test 'deletion after specified 14 days' do
    # delete (soft) first attachment
    assert_nil @attachment1.deleted_at
    @attachment1.destroy
    assert_not_nil @attachment1.deleted_at
    # go forward 10 days
    travel 10.days
    # delete (soft) second attachment
    assert_nil @attachment2.deleted_at
    @attachment2.destroy
    assert_not_nil @attachment2.deleted_at
    # go forward 6 more days
    travel 6.days
    # verify files are only soft deleted
    assert_not_nil @attachment1.deleted_at
    assert_not_nil @attachment2.deleted_at
    assert_nil @attachment3.deleted_at

    # run job and verify file/object count changes
    assert_difference -> { ActiveStorage::Attachment.count } => -1,
                      -> { Attachment.only_deleted.count } => -1,
                      -> { Attachment.count } => 0 do
      AttachmentsCleanupJob.perform_now(days_old: 14)
    end

    # verify attachment exist or not
    id_list = Attachment.all.map(&:id)
    assert_not(id_list.include?(@attachment1.id))
    assert_not(id_list.include?(@attachment2.id))
    assert(Attachment.only_deleted.map(&:id).include?(@attachment2.id))
    assert(id_list.include?(@attachment3.id))
  end

  test 'deletion multiple' do
    # delete (soft) first attachment
    assert_nil @attachment1.deleted_at
    @attachment1.destroy
    assert_not_nil @attachment1.deleted_at
    # delete (soft) second attachment
    assert_nil @attachment2.deleted_at
    @attachment2.destroy
    assert_not_nil @attachment2.deleted_at
    # go forward 9 days
    travel 9.days
    # verify files are only soft deleted
    assert_not_nil @attachment1.deleted_at
    assert_not_nil @attachment2.deleted_at
    assert_nil @attachment3.deleted_at

    # run job and verify file/object count changes
    assert_difference -> { ActiveStorage::Attachment.count } => -2,
                      -> { Attachment.only_deleted.count } => -2,
                      -> { Attachment.count } => 0 do
      AttachmentsCleanupJob.perform_now
    end

    # verify attachment exist or not
    id_list = Attachment.all.map(&:id)
    assert_not(id_list.include?(@attachment1.id))
    assert_not(id_list.include?(@attachment2.id))
    assert(id_list.include?(@attachment3.id))
  end

  test 'invalid argument string' do
    assert_raise(Exception) do
      AttachmentsCleanupJob.perform_now(days_old: 'this is not a number')
    end
  end

  test 'invalid argument negative' do
    assert_raise(Exception) do
      AttachmentsCleanupJob.perform_now(days_old: -1)
    end
  end

  test 'invalid argument zero' do
    assert_raise(Exception) do
      AttachmentsCleanupJob.perform_now(days_old: 0)
    end
  end

  test 'invalid argument int as string' do
    assert_raise(Exception) do
      AttachmentsCleanupJob.perform_now(days_old: '1')
    end
  end
end
