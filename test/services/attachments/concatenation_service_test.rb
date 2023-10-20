# frozen_string_literal: true

require 'test_helper'

module Attachments
  class ConcatenationServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:jeff_doe)
      @sample = samples(:sampleA)
    end

    test 'concatenate single end files' do
      params = { attachment_ids: [attachments(:attachmentA).id, attachments(:attachmentB).id] }

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
                                  [attachments(:attachmentPEFWD2).id, attachments(:attachmentPEREV2).id]] }

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

    test 'concatenate fastq.gz files' do
      sample = samples(:sampleB)
      params = { attachment_ids: [attachments(:attachmentE).id, attachments(:attachmentF).id] }

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
      params = { attachment_ids: [attachments(:attachmentPEFWD1).id, attachments(:attachmentD).id] }

      Attachments::ConcatenationService.new(@user, sample, params).execute

      assert sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.incorrect_file_types'))
    end

    test 'shouldn\'t concatenate fastq with fastq.gz files' do
      sample = samples(:sampleB)
      params = { attachment_ids: [attachments(:attachmentD).id, attachments(:attachmentE).id] }

      Attachments::ConcatenationService.new(@user, sample, params).execute

      assert sample.errors.full_messages.include?(
        I18n.t('services.attachments.concatenation.incorrect_fastq_file_types')
      )
    end

    test 'shouldn\'t concatenate files as they do not belong to the sample' do
      user = users(:john_doe)
      sample = samples(:sample2)
      params = { attachment_ids: [attachments(:attachmentA).id, attachments(:attachmentB).id] }

      Attachments::ConcatenationService.new(user, sample, params).execute

      assert sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.incorrect_attachable'))
    end
  end
end
