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
      params = { attachment_ids: { '0' => attachments(:attachmentG).id, '1' => attachments(:attachmentH).id },
                 basename: 'new-concatenated-file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 1 do
          Attachments::ConcatenationService.new(@user, sample, params).execute
        end

        attachmentg_file_size = sample.attachments.find_by(id: attachments(:attachmentG).id).file.byte_size
        attachmenth_file_size = sample.attachments.find_by(id: attachments(:attachmentH).id).file.byte_size

        concatenated_file_size = sample.attachments.last.file.byte_size

        assert_equal concatenated_file_size, (attachmentg_file_size + attachmenth_file_size)

        assert_equal 'new-concatenated-file_1.fastq', sample.attachments.last.file.filename.to_s

        assert_equal 'fastq', sample.attachments.last.metadata['format']

        assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'concatenate single end files with spaces in provided basename' do
      sample = samples(:sampleC)
      params = { attachment_ids: { '0' => attachments(:attachmentG).id, '1' => attachments(:attachmentH).id },
                 basename: 'new concatenated file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, sample, params).execute
        end

        assert sample.errors[:basename].include?(I18n.t('services.attachments.concatenation.incorrect_basename'))

        assert_equal sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'concatenate paired end files' do
      sample = samples(:sampleB)
      params = { attachment_ids: { '0' => [attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                   '1' => [attachments(:attachmentPEFWD2).id, attachments(:attachmentPEREV2).id] },
                 basename: 'new-concatenated-file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
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

        assert_equal 'new-concatenated-file_1.fastq', sample.attachments.last(2).first.file.filename.to_s
        assert_equal 'new-concatenated-file_2.fastq', sample.attachments.last(2).last.file.filename.to_s

        assert_equal 'fastq', sample.attachments.last(2).first.metadata['format']
        assert_equal 'fastq', sample.attachments.last(2).last.metadata['format']

        assert_equal 'pe', sample.attachments.last(2).first.metadata['type']
        assert_equal 'pe', sample.attachments.last(2).last.metadata['type']

        assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'concatenate paired end files with spaces in provided basename' do
      sample = samples(:sampleB)
      params = { attachment_ids: { '0' => [attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                   '1' => [attachments(:attachmentPEFWD2).id, attachments(:attachmentPEREV2).id] },
                 basename: 'new concatenated file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, sample, params).execute
        end

        assert sample.errors[:basename].include?(I18n.t('services.attachments.concatenation.incorrect_basename'))

        assert_equal sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'concatenate illumina paired end files' do
      sample = samples(:sampleC)
      params = { attachment_ids: { '0' => [attachments(:attachmentPEFWD4).id, attachments(:attachmentPEREV4).id],
                                   '1' => [attachments(:attachmentPEFWD5).id, attachments(:attachmentPEREV5).id] },
                 basename: 'new-concatenated-file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 2 do
          Attachments::ConcatenationService.new(@user, sample, params).execute
        end

        attachmentfwd4_file_size = sample.attachments.find_by(id: attachments(:attachmentPEFWD4).id).file.byte_size
        attachmentfwd5_file_size = sample.attachments.find_by(id: attachments(:attachmentPEFWD5).id).file.byte_size

        attachmentrev4_file_size = sample.attachments.find_by(id: attachments(:attachmentPEREV4).id).file.byte_size
        attachmentrev5_file_size = sample.attachments.find_by(id: attachments(:attachmentPEREV5).id).file.byte_size

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
    end

    test 'should concatenate more than 2 pairs of paired-end files' do
      sample = samples(:sampleB)
      params = { attachment_ids: { '0' => [attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                   '1' => [attachments(:attachmentPEFWD2).id,
                                           attachments(:attachmentPEREV2).id],
                                   '2' => [attachments(:attachmentPEFWD3).id,
                                           attachments(:attachmentPEREV3).id] },
                 basename: 'new-concatenated-file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
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

        assert_equal 'fastq', sample.attachments.last(2).first.metadata['format']
        assert_equal 'fastq', sample.attachments.last(2).last.metadata['format']

        assert_equal 'pe', sample.attachments.last(2).first.metadata['type']
        assert_equal 'pe', sample.attachments.last(2).last.metadata['type']

        assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'concatenate fastq.gz files' do
      sample = samples(:sampleB)
      params = { attachment_ids: { '0' => attachments(:attachmentE).id, '1' => attachments(:attachmentF).id },
                 basename: 'new-concatenated-file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 1 do
          Attachments::ConcatenationService.new(@user, sample, params).execute
        end

        attachmentgz1_file_size = sample.attachments.find_by(id: attachments(:attachmentE).id).file.byte_size
        attachmentgz2_file_size = sample.attachments.find_by(id: attachments(:attachmentF).id).file.byte_size

        concatenatedgz_file_size = sample.attachments.last.file.byte_size

        assert_equal concatenatedgz_file_size, (attachmentgz1_file_size + attachmentgz2_file_size)

        assert_equal 'new-concatenated-file_1.fastq.gz', sample.attachments.last.file.filename.to_s

        assert_equal 'fastq', sample.attachments.last.metadata['format']
        assert_equal 'gzip', sample.attachments.last.metadata['compression']

        assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'concatenate fq files' do
      sample = samples(:sampleC)
      params = { attachment_ids: { '0' => [attachments(:attachmentPEFWD6).id, attachments(:attachmentPEREV6).id],
                                   '1' => [attachments(:attachmentPEFWD7).id, attachments(:attachmentPEREV7).id] },
                 basename: 'new-concatenated-file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 2 do
          Attachments::ConcatenationService.new(@user, sample, params).execute
        end

        attachmentfwd6_file_size = sample.attachments.find_by(id: attachments(:attachmentPEFWD6).id).file.byte_size
        attachmentfwd7_file_size = sample.attachments.find_by(id: attachments(:attachmentPEFWD7).id).file.byte_size

        attachmentrev6_file_size = sample.attachments.find_by(id: attachments(:attachmentPEREV6).id).file.byte_size
        attachmentrev7_file_size = sample.attachments.find_by(id: attachments(:attachmentPEREV7).id).file.byte_size

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
    end

    test 'concatenate fq.gz files' do
      sample = samples(:sampleC)
      params = { attachment_ids: { '0' => attachments(:attachmentI).id, '1' => attachments(:attachmentJ).id },
                 basename: 'new-concatenated-file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_difference -> { Attachment.count } => 1 do
          Attachments::ConcatenationService.new(@user, sample, params).execute
        end

        attachmentgz1_file_size = sample.attachments.find_by(id: attachments(:attachmentI).id).file.byte_size
        attachmentgz2_file_size = sample.attachments.find_by(id: attachments(:attachmentJ).id).file.byte_size

        concatenatedgz_file_size = sample.attachments.last.file.byte_size

        assert_equal concatenatedgz_file_size, (attachmentgz1_file_size + attachmentgz2_file_size)

        assert_equal 'new-concatenated-file_1.fastq.gz', sample.attachments.last.file.filename.to_s

        assert_equal 'fastq', sample.attachments.last.metadata['format']
        assert_equal 'gzip', sample.attachments.last.metadata['compression']

        assert_not_equal sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'shouldn\'t concatenate single end with paired end files' do
      sample = samples(:sampleB)
      params = { attachment_ids: { '1' => attachments(:attachmentPEFWD1).id, '0' => attachments(:attachmentD).id },
                 basename: 'new-concatenated-file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, sample, params).execute
        end

        assert sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.incorrect_file_types'))

        assert_equal sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'shouldn\'t concatenate fastq with fastq.gz files' do
      sample = samples(:sampleB)
      params = { attachment_ids: { '0' => attachments(:attachmentD).id, '1' => attachments(:attachmentE).id },
                 basename: 'new-concatenated-file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, sample, params).execute
        end

        assert sample.errors.full_messages.include?(
          I18n.t('services.attachments.concatenation.incorrect_fastq_file_types')
        )

        assert_equal sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'shouldn\'t concatenate files as they do not belong to the sample' do
      user = users(:john_doe)
      sample = samples(:sample2)
      params = { attachment_ids: { '0' => attachments(:attachmentA).id, '1' => attachments(:attachmentB).id },
                 basename: 'new-concatenated-file' }

      assert_nil sample.attachments_updated_at

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(user, sample, params).execute
        end

        assert sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.incorrect_attachable'))

        assert_nil sample.reload.attachments_updated_at
      end
    end

    test 'shouldn\'t concatenate files when a base file name is not provided' do
      params = { attachment_ids: { '0' => attachments(:attachmentA).id, '1' => attachments(:attachmentB).id } }

      prev_timestamp = @sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, @sample, params).execute
        end

        assert @sample.errors[:basename].include?(I18n.t('services.attachments.concatenation.filename_missing'))

        assert_equal @sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'should throw an error if no files are selected for concatenation' do
      params = { attachment_ids: {},
                 basename: 'new-concatenated-file' }

      prev_timestamp = @sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, @sample, params).execute
        end

        assert @sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.no_files_selected'))

        assert_equal @sample.reload.attachments_updated_at, prev_timestamp
      end
    end

    test 'should throw an error if foward reads file count doesn\'t equal to reverse reads file count' do
      sample = samples(:sampleB)
      params = { attachment_ids: { '0' => [attachments(:attachmentPEFWD1).id, attachments(:attachmentPEREV1).id],
                                   '1' => attachments(:attachmentPEFWD2).id },
                 basename: 'new-concatenated-file' }

      prev_timestamp = sample.attachments_updated_at
      assert_not_nil prev_timestamp

      Timecop.travel(Time.zone.now + 5) do
        assert_no_difference -> { Attachment.count } do
          Attachments::ConcatenationService.new(@user, sample, params).execute
        end

        assert sample.errors.full_messages.include?(I18n.t('services.attachments.concatenation.incorrect_file_pairs'))

        assert_equal sample.reload.attachments_updated_at, prev_timestamp
      end
    end
  end
end
