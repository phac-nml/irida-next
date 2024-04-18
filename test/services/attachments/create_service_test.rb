# frozen_string_literal: true

require 'test_helper'

module Attachments
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample = samples(:sample2)
      @sample1 = samples(:sample1)
      @fastq_se_blob = active_storage_blobs(:test_file_fastq_blob)
      @testsample_illumina_pe_fwd_blob = active_storage_blobs(:testsample_illumina_pe_forward_blob)
      @testsample_illumina_pe_rev_blob = active_storage_blobs(:testsample_illumina_pe_reverse_blob)
      @testsample_illumina_without_lane_pe_fwd_blob =
        active_storage_blobs(:testsample_illumina_without_lane_pe_forward_blob)
      @testsample_illumina_without_lane_pe_rev_blob =
        active_storage_blobs(:testsample_illumina_without_lane_pe_reverse_blob)
    end

    test 'create attachments with valid params' do
      valid_params = { files: [@fastq_se_blob] }

      assert_nil @sample.attachments_updated_at

      assert_difference -> { Attachment.count } => 1 do
        Attachments::CreateService.new(@user, @sample, valid_params).execute
      end

      assert_not_nil @sample.attachments_updated_at
    end

    test 'create attachments with valid illumina paired end forward and reverse fastq files' do
      valid_params = { files: [@testsample_illumina_pe_fwd_blob,
                               @testsample_illumina_pe_rev_blob,
                               @testsample_illumina_without_lane_pe_fwd_blob,
                               @testsample_illumina_without_lane_pe_rev_blob] }

      assert_nil @sample.attachments_updated_at

      assert_difference -> { Attachment.count } => 4 do
        Attachments::CreateService.new(@user, @sample, valid_params).execute
      end

      created_attachments = @sample.attachments.last(4)

      assert created_attachments[0].metadata.key?('type')
      assert created_attachments[0].metadata['type'] == 'illumina_pe'
      assert created_attachments[0].metadata.key?('direction')
      assert created_attachments[0].metadata['direction'] == 'forward'
      assert created_attachments[0].metadata.key?('associated_attachment_id')
      assert created_attachments[0].metadata['associated_attachment_id'] == created_attachments[1].id

      assert created_attachments[1].metadata.key?('type')
      assert created_attachments[1].metadata['type'] == 'illumina_pe'
      assert created_attachments[1].metadata.key?('direction')
      assert created_attachments[1].metadata['direction'] == 'reverse'
      assert created_attachments[1].metadata.key?('associated_attachment_id')
      assert created_attachments[1].metadata['associated_attachment_id'] == created_attachments[0].id

      assert created_attachments[2].metadata.key?('type')
      assert created_attachments[2].metadata['type'] == 'illumina_pe'
      assert created_attachments[2].metadata.key?('direction')
      assert created_attachments[2].metadata['direction'] == 'forward'
      assert created_attachments[2].metadata.key?('associated_attachment_id')
      assert created_attachments[2].metadata['associated_attachment_id'] == created_attachments[3].id

      assert created_attachments[3].metadata.key?('type')
      assert created_attachments[3].metadata['type'] == 'illumina_pe'
      assert created_attachments[3].metadata.key?('direction')
      assert created_attachments[3].metadata['direction'] == 'reverse'
      assert created_attachments[3].metadata.key?('associated_attachment_id')
      assert created_attachments[3].metadata['associated_attachment_id'] == created_attachments[2].id

      assert_not_nil @sample.attachments_updated_at
    end

    test 'create attachments with valid paired end forward and reverse fastq filenames' do
      paired_blobs_list = [
        [active_storage_blobs(:attachmentK_file_test_file_fastq_blob),
         active_storage_blobs(:attachmentL_file_test_file_fastq_blob)],
        [active_storage_blobs(:attachmentM_file_test_file_fastq_blob),
         active_storage_blobs(:attachmentN_file_test_file_fastq_blob)],
        [active_storage_blobs(:attachmentO_file_test_file_fastq_blob),
         active_storage_blobs(:attachmentP_file_test_file_fastq_blob)],
        [active_storage_blobs(:attachmentQ_file_test_file_fastq_blob),
         active_storage_blobs(:attachmentR_file_test_file_fastq_blob)]
      ]

      assert_nil @sample.attachments_updated_at

      paired_blobs_list.each do |paired_blob|
        valid_params = { files: [paired_blob.first, paired_blob.last] }

        assert_difference -> { Attachment.count } => 2 do
          Attachments::CreateService.new(@user, @sample, valid_params).execute
        end

        created_attachments = Attachment.last(2)

        assert created_attachments.first.metadata.key?('type')
        assert created_attachments.first.metadata['type'] == 'pe'
        assert created_attachments.first.metadata.key?('direction')
        assert created_attachments.first.metadata['direction'] == 'forward'
        assert created_attachments.first.metadata.key?('associated_attachment_id')
        assert created_attachments.first.metadata['associated_attachment_id'] == created_attachments.last.id

        assert created_attachments.last.metadata.key?('type')
        assert created_attachments.last.metadata['type'] == 'pe'
        assert created_attachments.last.metadata.key?('direction')
        assert created_attachments.last.metadata['direction'] == 'reverse'
        assert created_attachments.last.metadata.key?('associated_attachment_id')
        assert created_attachments.last.metadata['associated_attachment_id'] == created_attachments.first.id
      end

      assert_not_nil @sample.attachments_updated_at
    end

    test 'create attachments with invalid paired end forward and reverse fastq filenames' do
      valid_params = { files: [active_storage_blobs(:attachmentR_file_test_file_fastq_blob),
                               active_storage_blobs(:attachmentS_file_test_file_fastq_blob)] }

      assert_nil @sample.attachments_updated_at

      assert_difference -> { Attachment.count } => 2 do
        Attachments::CreateService.new(@user, @sample, valid_params).execute
      end

      created_attachments = Attachment.last(2)

      assert_not created_attachments.first.metadata.key?('type')
      assert_not created_attachments.first.metadata.key?('direction')
      assert_not created_attachments.first.metadata.key?('associated_attachment_id')

      assert_not created_attachments.last.metadata.key?('type')
      assert_not created_attachments.last.metadata.key?('direction')
      assert_not created_attachments.last.metadata.key?('associated_attachment_id')

      assert_not_nil @sample.attachments_updated_at
    end

    test 'create attachments with valid illumina paired end forward fastq file' do
      valid_params = { files: [@testsample_illumina_pe_fwd_blob] }

      assert_nil @sample.attachments_updated_at

      assert_difference -> { Attachment.count } => 1 do
        Attachments::CreateService.new(@user, @sample, valid_params).execute
      end

      created_attachment = Attachment.last

      assert_not created_attachment.metadata.key?('type')
      assert_not created_attachment.metadata.key?('direction')
      assert_not created_attachment.metadata.key?('associated_attachment_id')

      assert_not_nil @sample.attachments_updated_at
    end

    test 'create attachments with valid illumina paired end reverse fastq file' do
      valid_params = { files: [@testsample_illumina_pe_rev_blob] }

      assert_nil @sample.attachments_updated_at

      assert_difference -> { Attachment.count } => 1 do
        Attachments::CreateService.new(@user, @sample, valid_params).execute
      end

      created_attachment = Attachment.last

      assert_not created_attachment.metadata.key?('type')
      assert_not created_attachment.metadata.key?('direction')
      assert_not created_attachment.metadata.key?('associated_attachment_id')

      assert_not_nil @sample.attachments_updated_at
    end

    test 'create attachments with empty params' do
      assert_nil @sample.attachments_updated_at

      assert_no_difference -> { Attachment.count } do
        Attachments::CreateService.new(@user, @sample, {}).execute
      end

      assert_nil @sample.attachments_updated_at
    end

    test 'create attachments with empty files params' do
      assert_nil @sample.attachments_updated_at

      assert_no_difference -> { Attachment.count } do
        Attachments::CreateService.new(@user, @sample, { files: [''] }).execute
      end

      assert_nil @sample.attachments_updated_at
    end

    test 'create attachments with file matching existing checksum' do
      params = { files: [@fastq_se_blob] }

      assert_nil @sample.attachments_updated_at

      assert_no_difference -> { Attachment.count } do
        Attachments::CreateService.new(@user, @sample1, params).execute
      end

      assert_nil @sample.attachments_updated_at
    end
  end
end
