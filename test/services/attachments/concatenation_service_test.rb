# frozen_string_literal: true

require 'test_helper'

module Attachments
  class ConcatenationServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:jeff_doe)
      @sample = samples(:sampleA)
    end

    test 'concatenate single end files' do
      params = { attachment_ids: [attachments(:attachmentA).id, attachments(:attachmentB).id],
                 basename: 'new-concatenated-file' }

      assert_difference -> { Attachment.count } => 1 do
        Attachments::ConcatenationService.new(@user, @sample, params).execute
      end

      attachmenta_file_size = @sample.attachments.find_by(id: attachments(:attachmentA).id).file.byte_size
      attachmentb_file_size = @sample.attachments.find_by(id: attachments(:attachmentB).id).file.byte_size

      concatenated_file_size = @sample.attachments.last.file.byte_size

      assert_equal concatenated_file_size, (attachmenta_file_size + attachmentb_file_size)
    end

    test 'concatenate paired end files' do
      sample = samples(:sampleB)
      params = { attachment_ids: [[attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                  [attachments(:attachmentPEFWD2).id, attachments(:attachmentPEREV2).id]],
                 basename: 'new-concatenated-file' }

      assert_difference -> { Attachment.count } => 2 do
        Attachments::ConcatenationService.new(@user, sample, params).execute
      end

      attachmentfwd1_file_size = sample.attachments.find_by(id: attachments(:attachmentPEFWD1).id).file.byte_size
      attachmentfwd2_file_size = sample.attachments.find_by(id: attachments(:attachmentPEFWD2).id).file.byte_size

      attachmentrev1_file_size = sample.attachments.find_by(id: attachments(:attachmentPEREV1).id).file.byte_size
      attachmentrev2_file_size = sample.attachments.find_by(id: attachments(:attachmentPEREV2).id).file.byte_size

      concatenatedfwd_file_size = sample.attachments.last(2).first.file.byte_size
      concatenatedrev_file_size = sample.attachments.last(2).last.file.byte_size

      assert_equal concatenatedfwd_file_size, (attachmentfwd1_file_size + attachmentfwd2_file_size)

      assert_equal concatenatedrev_file_size, (attachmentrev1_file_size + attachmentrev2_file_size)
    end

    test 'should concatenate more than 2 pairs of paired-end files' do
      sample = samples(:sampleB)
      params = { attachment_ids: [[attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                  [attachments(:attachmentPEFWD2).id, attachments(:attachmentPEREV2).id],
                                  [attachments(:attachmentPEFWD3).id, attachments(:attachmentPEREV3).id]],
                 basename: 'new-concatenated-file' }

      assert_difference -> { Attachment.count } => 2 do
        Attachments::ConcatenationService.new(@user, sample, params).execute
      end

      attachmentfwd1_file_size = sample.attachments.find_by(id: attachments(:attachmentPEFWD1).id).file.byte_size
      attachmentfwd2_file_size = sample.attachments.find_by(id: attachments(:attachmentPEFWD2).id).file.byte_size
      attachmentfwd3_file_size = sample.attachments.find_by(id: attachments(:attachmentPEFWD3).id).file.byte_size

      attachmentrev1_file_size = sample.attachments.find_by(id: attachments(:attachmentPEREV1).id).file.byte_size
      attachmentrev2_file_size = sample.attachments.find_by(id: attachments(:attachmentPEREV2).id).file.byte_size
      attachmentrev3_file_size = sample.attachments.find_by(id: attachments(:attachmentPEREV3).id).file.byte_size

      concatenatedfwd_file_size = sample.attachments.last(2).first.file.byte_size
      concatenatedrev_file_size = sample.attachments.last(2).last.file.byte_size

      assert_equal concatenatedfwd_file_size,
                   (attachmentfwd1_file_size + attachmentfwd2_file_size + attachmentfwd3_file_size)

      assert_equal concatenatedrev_file_size,
                   (attachmentrev1_file_size + attachmentrev2_file_size + attachmentrev3_file_size)
    end

    test 'concatenate fastq.gz files' do
      sample = samples(:sampleB)
      params = { attachment_ids: [attachments(:attachmentE).id, attachments(:attachmentF).id],
                 basename: 'new-concatenated-file' }

      assert_difference -> { Attachment.count } => 1 do
        Attachments::ConcatenationService.new(@user, sample, params).execute
      end

      attachmentgz1_file_size = sample.attachments.find_by(id: attachments(:attachmentE).id).file.byte_size
      attachmentgz2_file_size = sample.attachments.find_by(id: attachments(:attachmentF).id).file.byte_size

      concatenatedgz_file_size = sample.attachments.last.file.byte_size

      assert_equal concatenatedgz_file_size, (attachmentgz1_file_size + attachmentgz2_file_size)
    end

    test 'shouldn\'t concatenate single end with paired end files' do
      sample = samples(:sampleB)
      params = { attachment_ids: [attachments(:attachmentPEFWD1).id, attachments(:attachmentD).id],
                 basename: 'new-concatenated-file' }

      Attachments::ConcatenationService.new(@user, sample, params).execute

      assert sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.incorrect_file_types'))
    end

    test 'shouldn\'t concatenate fastq with fastq.gz files' do
      sample = samples(:sampleB)
      params = { attachment_ids: [attachments(:attachmentD).id, attachments(:attachmentE).id],
                 basename: 'new-concatenated-file' }

      Attachments::ConcatenationService.new(@user, sample, params).execute

      assert sample.errors.full_messages.include?(
        I18n.t('services.attachments.concatenation.incorrect_fastq_file_types')
      )
    end

    test 'shouldn\'t concatenate files as they do not belong to the sample' do
      user = users(:john_doe)
      sample = samples(:sample2)
      params = { attachment_ids: [attachments(:attachmentA).id, attachments(:attachmentB).id],
                 basename: 'new-concatenated-file' }

      Attachments::ConcatenationService.new(user, sample, params).execute

      assert sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.incorrect_attachable'))
    end

    test 'shouldn\'t concatenate files when a base file name is not provided' do
      params = { attachment_ids: [attachments(:attachmentA).id, attachments(:attachmentB).id] }

      assert_no_difference -> { Attachment.count } do
        Attachments::ConcatenationService.new(@user, @sample, params).execute
      end

      assert @sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.filename_missing'))
    end

    test 'should throw an error if no files are selected for concatenation' do
      params = { attachment_ids: [],
                 basename: 'new-concatenated-file' }

      assert_no_difference -> { Attachment.count } do
        Attachments::ConcatenationService.new(@user, @sample, params).execute
      end

      assert @sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.no_files_selected'))
    end

    test 'should throw an error if foward reads file count doesn\'t equal to reverse reads file count' do
      sample = samples(:sampleB)
      params = { attachment_ids: [[attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                  [attachments(:attachmentPEFWD2).id]],
                 basename: 'new-concatenated-file' }

      assert_no_difference -> { Attachment.count } do
        Attachments::ConcatenationService.new(@user, sample, params).execute
      end

      assert sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.incorrect_file_pairs'))
    end
  end
end
