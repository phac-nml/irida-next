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
    end

    test 'create attachments with valid params' do
      valid_params = { files: [@fastq_se_blob] }

      assert_difference -> { Attachment.count } => 1 do
        Attachments::CreateService.new(@user, @sample, valid_params).execute
      end
    end

    test 'create attachments with valid illumina paired end forward and reverse fastq files' do
      valid_params = { files: [@testsample_illumina_pe_fwd_blob, @testsample_illumina_pe_rev_blob] }

      assert_difference -> { Attachment.count } => 2 do
        Attachments::CreateService.new(@user, @sample, valid_params).execute
      end

      created_attachments = Attachment.last(2)

      assert created_attachments.first.metadata.key?('type')
      assert created_attachments.first.metadata['type'] == 'illumina_pe'
      assert created_attachments.first.metadata.key?('direction')
      assert created_attachments.first.metadata['direction'] == 'forward'
      assert created_attachments.first.metadata.key?('associated_attachment_id')
      assert created_attachments.first.metadata['associated_attachment_id'] == created_attachments.last.id

      assert created_attachments.last.metadata.key?('type')
      assert created_attachments.last.metadata['type'] == 'illumina_pe'
      assert created_attachments.last.metadata.key?('direction')
      assert created_attachments.last.metadata['direction'] == 'reverse'
      assert created_attachments.last.metadata.key?('associated_attachment_id')
      assert created_attachments.last.metadata['associated_attachment_id'] == created_attachments.first.id
    end

    test 'create attachments with valid paired end forward and reverse fastq files' do
      valid_params = { files: [active_storage_blobs(:attachmentK_gz_file_test_file_fastq_blob),
                               active_storage_blobs(:attachmentL_gz_file_test_file_fastq_blob)] }

      assert_difference -> { Attachment.count } => 2 do
        Attachments::CreateService.new(@user, @sample, valid_params).execute
      end

      created_attachments = Attachment.last(2)

      assert created_attachments.first.metadata.key?('type')
      assert created_attachments.first.metadata['type'] == 'pe'
      assert created_attachments.first.metadata.key?('direction')
      assert created_attachments.first.metadata['direction'] == 'forward'
      assert created_attachments.first.metadata.key?('compression')
      assert created_attachments.first.metadata['compression'] == 'gzip'
      assert created_attachments.first.metadata.key?('associated_attachment_id')
      assert created_attachments.first.metadata['associated_attachment_id'] == created_attachments.last.id

      assert created_attachments.last.metadata.key?('type')
      assert created_attachments.last.metadata['type'] == 'pe'
      assert created_attachments.last.metadata.key?('direction')
      assert created_attachments.last.metadata['direction'] == 'reverse'
      assert created_attachments.first.metadata.key?('compression')
      assert created_attachments.first.metadata['compression'] == 'gzip'
      assert created_attachments.last.metadata.key?('associated_attachment_id')
      assert created_attachments.last.metadata['associated_attachment_id'] == created_attachments.first.id
    end

    test 'create attachments with valid illumina paired end forward fastq file' do
      valid_params = { files: [@testsample_illumina_pe_fwd_blob] }

      assert_difference -> { Attachment.count } => 1 do
        Attachments::CreateService.new(@user, @sample, valid_params).execute
      end

      created_attachment = Attachment.last

      assert_not created_attachment.metadata.key?('type')
      assert_not created_attachment.metadata.key?('direction')
      assert_not created_attachment.metadata.key?('associated_attachment_id')
    end

    test 'create attachments with valid illumina paired end reverse fastq file' do
      valid_params = { files: [@testsample_illumina_pe_rev_blob] }

      assert_difference -> { Attachment.count } => 1 do
        Attachments::CreateService.new(@user, @sample, valid_params).execute
      end

      created_attachment = Attachment.last

      assert_not created_attachment.metadata.key?('type')
      assert_not created_attachment.metadata.key?('direction')
      assert_not created_attachment.metadata.key?('associated_attachment_id')
    end

    test 'create attachments with empty params' do
      assert_no_difference -> { Attachment.count } do
        Attachments::CreateService.new(@user, @sample, {}).execute
      end
    end

    test 'create attachments with empty files params' do
      assert_no_difference -> { Attachment.count } do
        Attachments::CreateService.new(@user, @sample, { files: [''] }).execute
      end
    end

    test 'create attachments with file matching existing checksum' do
      params = { files: [@fastq_se_blob] }

      assert_no_difference -> { Attachment.count } do
        Attachments::CreateService.new(@user, @sample1, params).execute
      end
    end
  end
end
