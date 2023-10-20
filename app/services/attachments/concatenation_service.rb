# frozen_string_literal: true

module Attachments
  # Service used to Concatenate Attachments
  class ConcatenationService < BaseService
    AttachmentConcatenationError = Class.new(StandardError)

    attr_accessor :attachable, :attachments, :concatenation_params

    def initialize(user = nil, attachable = nil, params = {})
      super(user, params)
      @attachable = attachable

      # single-end params: { attachment_ids = [], basename: basefilename OPTIONAL,
      #                      delete_originals: true OPTIONAL
      #                      }
      # paired-end params: { attachment_ids = [[],[]], basename: basefilename OPTIONAL,
      #                      delete_originals: true OPTIONAL
      #                      }
      @concatenation_params = params
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      # authorize if user can update sample
      authorize! attachable.project, to: :update_sample? if attachable.instance_of?(Sample)

      attachment_ids = concatenation_params[:attachment_ids]

      unless attachment_ids.all? { |i| i.is_a?(Integer) }
        # if multi-dimensional array of ids
        attachment_ids = attachment_ids.first + attachment_ids.last
      end

      attachments = attachable.attachments.where(id: attachment_ids, attachable:).order(:id)

      if attachments.length != attachment_ids.length
        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.incorrect_attachable')
      end

      if attachments.length.positive?
        is_paired_end = attachments.first.metadata.key?('type')
        is_single_end = !attachments.first.metadata.key?('type')

        validate_same_types(attachments, is_paired_end, is_single_end)

        if is_paired_end
          forward_reads = []
          reverse_reads = []
          attachments.each do |attachment|
            if attachment.metadata['direction'] == 'forward'
              forward_reads << attachment
            elsif attachment.metadata['direction'] == 'reverse'
              reverse_reads << attachment
            end
          end
          concatenate_paired_end_reads(forward_reads, reverse_reads)
        elsif is_single_end
          concatenate_single_end_reads(attachments)
        end

        # if option is selected then destroy the original files
        attachments.each(&:destroy!) if concatenation_params[:delete_originals]
      end
    rescue Attachments::ConcatenationService::AttachmentConcatenationError => e
      attachable.errors.add(:base, e.message)
      attachable
    end

    private

    # Validates attachments to ensure they are of the correct type.
    # Files can only be concatenated as follows. No mixing of types:
    # Paired-end -> Paired-end
    # Single-end -> Single-end
    def validate_same_types(attachments, is_paired_end, is_single_end) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      valid_type = true

      attachments.each do |attachment|
        if is_single_end
          valid_type = !attachment.metadata.key?('type')
        elsif is_paired_end
          valid_type = attachment.metadata.key?('type')
        end
      end

      if valid_type
        expected_extension = attachments.first.file.filename.to_s.partition('.').last
        attachments.each do |attachment|
          extension = attachment.file.filename.to_s.partition('.').last
          next unless extension != expected_extension

          valid_type = false
          raise AttachmentConcatenationError,
                I18n.t('services.attachments.concatenation.incorrect_fastq_file_types')
        end
      end

      return if valid_type

      raise AttachmentConcatenationError,
            I18n.t('services.attachments.concatenation.incorrect_file_types')
    end

    # Concatenates the single end reads into a single-end file
    def concatenate_single_end_reads(attachments)
      basename = concatenation_params[:basename] || 'concatenated_file'
      extension = attachments.first.file.filename.to_s.partition('.').last

      extension = 'fastq.gz' if extension == 'gz'

      blobs = []
      attachments.each do |attachment|
        blobs << attachment.file.blob
      end

      composed_blob = ActiveStorage::Blob.compose(blobs, filename: "#{basename}_S1_L001_R1_001.#{extension}")

      Attachments::CreateService.new(current_user, attachable, { files: [composed_blob.signed_id] }).execute
    end

    # Concatenates the paired-end reads into a multiple paired-end files
    def concatenate_paired_end_reads(forward_reads, reverse_reads) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      basename = concatenation_params[:basename] || 'concatenated_file'
      extension = forward_reads.first.file.filename.to_s.partition('.').last

      extension = 'fastq.gz' if extension == 'gz'

      files = []
      if forward_reads.length.positive?
        blobs = []
        forward_reads.each do |forward_read|
          blobs << forward_read.file.blob
        end

        composed_blob_fwd = ActiveStorage::Blob.compose(blobs, filename: "#{basename}_S1_L001_R1_001.#{extension}")
        files << composed_blob_fwd.signed_id
      end

      if reverse_reads.length.positive?
        blobs = []
        reverse_reads.each do |reverse_read|
          blobs << reverse_read.file.blob
        end

        composed_blob_rev = ActiveStorage::Blob.compose(blobs, filename: "#{basename}_S1_L001_R2_001.#{extension}")
        files << composed_blob_rev.signed_id
      end

      Attachments::CreateService.new(current_user, attachable, { files: }).execute
    end
  end
end
