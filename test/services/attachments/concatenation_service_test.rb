# frozen_string_literal: true

require 'test_helper'

module Attachments
  class ConcatenationServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:jeff_doe)
      @sample = samples(:sampleA)
    end

    test 'concatenate single end files' do
      sample = samples(:sampleC)
      params = {
        attachable_id: sample.id, attachable_type: sample.class.name,
        attachment_ids: { '0' => attachments(:attachmentG).id, '1' => attachments(:attachmentH).id },
        basename: 'new-concatenated-file'
      }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 1 do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      attachmentg_file_size = attachments(:attachmentG).file.byte_size
      attachmenth_file_size = attachments(:attachmentH).file.byte_size

      concatenated_file_size = sample.attachments.last.file.byte_size

      assert_equal concatenated_file_size, (attachmentg_file_size + attachmenth_file_size)

      assert_equal 'new-concatenated-file_1.fastq', sample.attachments.last.file.filename.to_s

      assert_equal 'fastq', sample.attachments.last.metadata['format']

      assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'concatenate single end files with spaces in provided basename' do
      sample = samples(:sampleC)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => attachments(:attachmentG).id, '1' => attachments(:attachmentH).id },
                 basename: 'new concatenated file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      assert concatenation_form.errors.of_kind?(:basename, :invalid)

      assert_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'concatenate paired end files' do
      sample = samples(:sampleB)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => [attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                   '1' => [attachments(:attachmentPEFWD2).id, attachments(:attachmentPEREV2).id] },
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 2 do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      attachmentfwd1_file_size = attachments(:attachmentPEFWD1).file.byte_size
      attachmentfwd2_file_size = attachments(:attachmentPEFWD2).file.byte_size

      attachmentrev1_file_size = attachments(:attachmentPEREV1).file.byte_size
      attachmentrev2_file_size = attachments(:attachmentPEREV2).file.byte_size

      concatenatedfwd_file_size = sample.attachments.last(2).first.file.byte_size
      concatenatedrev_file_size = sample.attachments.last(2).last.file.byte_size

      assert_equal concatenatedfwd_file_size, (attachmentfwd1_file_size + attachmentfwd2_file_size)

      assert_equal concatenatedrev_file_size, (attachmentrev1_file_size + attachmentrev2_file_size)

      assert_equal 'new-concatenated-file_1.fastq', sample.attachments.last(2).first.file.filename.to_s
      assert_equal 'new-concatenated-file_2.fastq', sample.attachments.last(2).last.file.filename.to_s

      assert_equal attachments(:attachmentPEFWD1).file.download + attachments(:attachmentPEFWD2).file.download,
                   sample.attachments.last(2).first.file.download
      assert_equal attachments(:attachmentPEREV1).file.download + attachments(:attachmentPEREV2).file.download,
                   sample.attachments.last(2).last.file.download

      assert_equal 'fastq', sample.attachments.last(2).first.metadata['format']
      assert_equal 'fastq', sample.attachments.last(2).last.metadata['format']

      assert_equal 'pe', sample.attachments.last(2).first.metadata['type']
      assert_equal 'pe', sample.attachments.last(2).last.metadata['type']

      assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'concatenate paired end files with spaces in provided basename' do
      sample = samples(:sampleB)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => [attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                   '1' => [attachments(:attachmentPEFWD2).id, attachments(:attachmentPEREV2).id] },
                 basename: 'new concatenated file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      assert concatenation_form.errors.of_kind?(:basename, :invalid)

      assert_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'concatenate illumina paired end files' do
      sample = samples(:sampleC)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => [attachments(:attachmentPEFWD4).id, attachments(:attachmentPEREV4).id],
                                   '1' => [attachments(:attachmentPEFWD5).id, attachments(:attachmentPEREV5).id] },
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 2 do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      attachmentfwd4_file_size = attachments(:attachmentPEFWD4).file.byte_size
      attachmentfwd5_file_size = attachments(:attachmentPEFWD5).file.byte_size

      attachmentrev4_file_size = attachments(:attachmentPEREV4).file.byte_size
      attachmentrev5_file_size = attachments(:attachmentPEREV5).file.byte_size

      concatenatedfwd_file_size = sample.attachments.last(2).first.file.byte_size
      concatenatedrev_file_size = sample.attachments.last(2).last.file.byte_size

      assert_equal concatenatedfwd_file_size, (attachmentfwd4_file_size + attachmentfwd5_file_size)

      assert_equal concatenatedrev_file_size, (attachmentrev4_file_size + attachmentrev5_file_size)

      assert_equal 'new-concatenated-file_S1_L001_R1_001.fastq', sample.attachments.last(2).first.file.filename.to_s
      assert_equal 'new-concatenated-file_S1_L001_R2_001.fastq', sample.attachments.last(2).last.file.filename.to_s

      assert_equal 'fastq', sample.attachments.last(2).first.metadata['format']
      assert_equal 'fastq', sample.attachments.last(2).last.metadata['format']

      assert_equal 'illumina_pe', sample.attachments.last(2).first.metadata['type']
      assert_equal 'illumina_pe', sample.attachments.last(2).last.metadata['type']

      assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'should concatenate more than 2 pairs of paired-end files' do
      sample = samples(:sampleB)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => [attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                   '1' => [attachments(:attachmentPEFWD2).id,
                                           attachments(:attachmentPEREV2).id],
                                   '2' => [attachments(:attachmentPEFWD3).id,
                                           attachments(:attachmentPEREV3).id] },
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 2 do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      attachmentfwd1_file_size = attachments(:attachmentPEFWD1).file.byte_size
      attachmentfwd2_file_size = attachments(:attachmentPEFWD2).file.byte_size
      attachmentfwd3_file_size = attachments(:attachmentPEFWD3).file.byte_size

      attachmentrev1_file_size = attachments(:attachmentPEREV1).file.byte_size
      attachmentrev2_file_size = attachments(:attachmentPEREV2).file.byte_size
      attachmentrev3_file_size = attachments(:attachmentPEREV3).file.byte_size

      concatenatedfwd_file_size = sample.attachments.last(2).first.file.byte_size
      concatenatedrev_file_size = sample.attachments.last(2).last.file.byte_size

      assert_equal concatenatedfwd_file_size,
                   (attachmentfwd1_file_size + attachmentfwd2_file_size + attachmentfwd3_file_size)

      assert_equal concatenatedrev_file_size,
                   (attachmentrev1_file_size + attachmentrev2_file_size + attachmentrev3_file_size)

      assert_equal 'fastq', sample.attachments.last(2).first.metadata['format']
      assert_equal 'fastq', sample.attachments.last(2).last.metadata['format']

      assert_equal 'pe', sample.attachments.last(2).first.metadata['type']
      assert_equal 'pe', sample.attachments.last(2).last.metadata['type']

      assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'concatenate fastq.gz files' do
      sample = samples(:sampleB)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => attachments(:attachmentE).id, '1' => attachments(:attachmentF).id },
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 1 do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      attachmentgz1_file_size = attachments(:attachmentE).file.byte_size
      attachmentgz2_file_size = attachments(:attachmentF).file.byte_size

      concatenatedgz_file_size = sample.attachments.last.file.byte_size

      assert_equal concatenatedgz_file_size, (attachmentgz1_file_size + attachmentgz2_file_size)

      assert_equal 'new-concatenated-file_1.fastq.gz', sample.attachments.last.file.filename.to_s

      assert_equal 'fastq', sample.attachments.last.metadata['format']
      assert_equal 'gzip', sample.attachments.last.metadata['compression']

      assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'concatenate fq files' do
      sample = samples(:sampleC)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => [attachments(:attachmentPEFWD6).id, attachments(:attachmentPEREV6).id],
                                   '1' => [attachments(:attachmentPEFWD7).id, attachments(:attachmentPEREV7).id] },
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 2 do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      attachmentfwd6_file_size = attachments(:attachmentPEFWD6).file.byte_size
      attachmentfwd7_file_size = attachments(:attachmentPEFWD7).file.byte_size

      attachmentrev6_file_size = attachments(:attachmentPEREV6).file.byte_size
      attachmentrev7_file_size = attachments(:attachmentPEREV7).file.byte_size

      concatenatedfwd_file_size = sample.attachments.last(2).first.file.byte_size
      concatenatedrev_file_size = sample.attachments.last(2).last.file.byte_size

      assert_equal concatenatedfwd_file_size, (attachmentfwd6_file_size + attachmentfwd7_file_size)

      assert_equal concatenatedrev_file_size, (attachmentrev6_file_size + attachmentrev7_file_size)

      assert_equal 'new-concatenated-file_S1_L001_R1_001.fastq', sample.attachments.last(2).first.file.filename.to_s
      assert_equal 'new-concatenated-file_S1_L001_R2_001.fastq', sample.attachments.last(2).last.file.filename.to_s

      assert_equal 'fastq', sample.attachments.last(2).first.metadata['format']
      assert_equal 'fastq', sample.attachments.last(2).last.metadata['format']

      assert_equal 'illumina_pe', sample.attachments.last(2).first.metadata['type']
      assert_equal 'illumina_pe', sample.attachments.last(2).last.metadata['type']

      assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'concatenate fq.gz files' do
      sample = samples(:sampleC)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => attachments(:attachmentI).id, '1' => attachments(:attachmentJ).id },
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 1 do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      attachmentgz1_file_size = attachments(:attachmentI).file.byte_size
      attachmentgz2_file_size = attachments(:attachmentJ).file.byte_size

      concatenatedgz_file_size = sample.attachments.last.file.byte_size

      assert_equal concatenatedgz_file_size, (attachmentgz1_file_size + attachmentgz2_file_size)

      assert_equal 'new-concatenated-file_1.fastq.gz', sample.attachments.last.file.filename.to_s

      assert_equal 'fastq', sample.attachments.last.metadata['format']
      assert_equal 'gzip', sample.attachments.last.metadata['compression']

      assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'shouldn\'t concatenate single end with paired end files' do
      sample = samples(:sampleB)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '1' => attachments(:attachmentPEFWD1).id, '0' => attachments(:attachmentD).id },
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      assert concatenation_form.errors.of_kind?(:attachment_ids, :mismatching_file_types)

      assert_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'shouldn\'t concatenate fastq with fastq.gz files' do
      sample = samples(:sampleB)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => attachments(:attachmentD).id, '1' => attachments(:attachmentE).id },
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      assert concatenation_form.errors.of_kind?(:attachment_ids, :mismatching_file_formats)

      assert_equal sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'shouldn\'t concatenate files as they do not belong to the sample' do
      user = users(:john_doe)
      sample = samples(:sample2)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => attachments(:attachmentA).id, '1' => attachments(:attachmentB).id },
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      assert_nil sample.attachments_updated_at

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(user, concatenation_form).execute
        end
      end

      assert concatenation_form.errors.of_kind?(:attachment_ids, :mismatching_attachable)

      assert_nil sample.reload.attachments_updated_at
    end

    test 'shouldn\'t concatenate files when a base file name is not provided' do
      params = { attachable_id: @sample.id, attachable_type: @sample.class.name,
                 attachment_ids: { '0' => attachments(:attachmentA).id, '1' => attachments(:attachmentB).id } }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = @sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      assert concatenation_form.errors.of_kind?(:basename, :blank)

      assert_equal @sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'should throw an error if no files are selected for concatenation' do
      params = { attachable_id: @sample.id, attachable_type: @sample.class.name,
                 attachment_ids: {},
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = @sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      assert concatenation_form.errors.of_kind?(:attachment_ids, :blank)

      assert_equal @sample.reload.attachments_updated_at, prev_timestamp
    end

    test 'should throw an error if foward reads file count doesn\'t equal to reverse reads file count' do
      sample = samples(:sampleB)
      params = { attachable_id: sample.id, attachable_type: sample.class.name,
                 attachment_ids: { '0' => [attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                   '1' => attachments(:attachmentPEFWD2).id },
                 basename: 'new-concatenated-file' }

      concatenation_form = ConcatenationForm.new(params)

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, concatenation_form).execute
        end
      end

      assert concatenation_form.errors.of_kind?(:attachment_ids, :mismatching_paired_end_counts)

      assert_equal sample.reload.attachments_updated_at, prev_timestamp
    end
  end
end
