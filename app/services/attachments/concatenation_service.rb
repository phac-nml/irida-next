# frozen_string_literal: true

module Attachments
  # Service used to Concatenate Attachments
  class ConcatenationService < BaseService # rubocop:disable Metrics/ClassLength
    AttachmentConcatenationError = Class.new(StandardError)

    attr_accessor :attachable, :attachments, :concatenation_params

    def initialize(user = nil, attachable = nil, params = {})
      super(user, params)
      @attachable = attachable

      # single-end params: { attachment_ids = {}, basename: basefilename,
      #                      delete_originals: true OPTIONAL
      #                      }
      # paired-end params: { attachment_ids = {{}, {}, ...}, basename: basefilename,
      #                      delete_originals: true OPTIONAL
      #                      }
      @concatenation_params = params
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # authorize if user can update sample
      authorize! attachable.project, to: :update_sample? if attachable.instance_of?(Sample)

      validate_params
      attachment_ids = concatenation_params[:attachment_ids].values
      is_paired_end = false

      unless attachment_ids.all? { |i| i.is_a?(Integer) || i.is_a?(String) }
        # if multi-dimensional array of ids
        attachment_ids = attachment_ids.flatten
        is_paired_end = true
      end

      attachments = attachable.attachments.where(id: attachment_ids, attachable:).order(:id)

      # Checks to make sure the selected attachments to concatenate
      # do in fact belong to the same sample
      if attachments.length != attachment_ids.length
        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.incorrect_attachable')
      end

      validate_and_concatenate(attachments, is_paired_end)
    rescue Attachments::ConcatenationService::AttachmentConcatenationError => e
      attachable.errors.add(:base, e.message)
      []
    end

    private

    # Validates params
    def validate_params # rubocop:disable Metrics/AbcSize
      if !concatenation_params.key?(:attachment_ids) || concatenation_params[:attachment_ids].empty?
        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.no_files_selected')
      end

      if !concatenation_params.key?(:basename) || concatenation_params[:basename].empty?
        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.filename_missing')
      end

      if concatenation_params.key?(:basename) && !concatenation_params[:basename].match?(/^[[a-zA-Z0-9_\-\.]]*$/)
        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.incorrect_basename')
      end

      true
    end

    # Calls the validation, concatenate methods for the file type
    # If the user selects to delete the originals the originals
    # are deleted
    def validate_and_concatenate(attachments, is_paired_end)
      return unless attachments.length.positive?

      validate_file_formats(attachments)

      concatenated_attachments = []

      if is_paired_end
        validate_paired_end_files(attachments)
        concatenated_attachments = concatenate_paired_end_reads(attachments)
      else
        validate_single_end_files(attachments)
        concatenated_attachments = concatenate_single_end_reads(attachments)
      end

      # if option is selected then destroy the original files
      attachments.each(&:destroy) if concatenation_params[:delete_originals]

      concatenated_attachments
    end

    # Validates that the single end files are all the same type
    def validate_single_end_files(attachments)
      attachments.each do |attachment|
        next unless attachment.metadata.key?('type')

        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.incorrect_file_types')
      end
      true
    end

    # Validates that the paired end files are all the same type
    def validate_paired_end_files(attachments)
      attachments.each do |attachment|
        if attachment.metadata.key?('type') && (attachments.first.metadata['type'] == 'illumina_pe' ||
          attachments.first.metadata['type'] == 'pe')
          next
        end

        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.incorrect_file_types')
      end
      true
    end

    # Validates if the file formats all match for the attachments
    def validate_file_formats(attachments)
      attachments.each do |attachment|
        next unless (attachment.metadata['compression'] != attachments.first.metadata['compression']) ||
                    (attachment.metadata['format'] != attachments.first.metadata['format'])

        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.incorrect_fastq_file_types')
      end
      true
    end

    # Concatenates the single end reads into a single-end file
    def concatenate_single_end_reads(attachments)
      basename = concatenation_params[:basename]
      zipped_extension = attachments.first.metadata['compression'] == 'gzip' ? '.gz' : ''

      files = []
      files << concatenate_attachments(attachments,
                                       "#{basename}_1.fastq#{zipped_extension}")
               .signed_id

      Attachments::CreateService.new(current_user, attachable, { files: }).execute
    end

    # Concatenates the paired-end reads into a multiple paired-end files
    def concatenate_paired_end_reads(attachments)
      zipped_extension = attachments.first.metadata['compression'] == 'gzip' ? '.gz' : ''

      fwd_filename, rev_filename = concatenated_paired_end_filenames(
        attachments.first.metadata['type']
      )

      forward_reads, reverse_reads = attachments_to_paired_end_directional_reads(attachments)

      files = []
      files <<
        concatenate_attachments(forward_reads,
                                "#{fwd_filename}.fastq#{zipped_extension}")
        .signed_id <<
        concatenate_attachments(reverse_reads,
                                "#{rev_filename}.fastq#{zipped_extension}")
        .signed_id

      Attachments::CreateService.new(current_user, attachable, { files: }).execute
    end

    # Gets the filename in the correct format for illumina paired-end and paired-end files
    def concatenated_paired_end_filenames(attachment_type)
      basename = concatenation_params[:basename]

      fwd_filename = attachment_type == 'illumina_pe' ? "#{basename}_S1_L001_R1_001" : "#{basename}_1"

      rev_filename = attachment_type == 'illumina_pe' ? "#{basename}_S1_L001_R2_001" : "#{basename}_2"

      [fwd_filename, rev_filename]
    end

    def concatenate_attachments(attachments, filename)
      blobs = retrieve_attachment_blobs(attachments)
      ActiveStorage::Blob.compose(blobs, filename:)
    end

    # Separates attachments into forward and reverse reads
    def attachments_to_paired_end_directional_reads(attachments)
      forward_reads = []
      reverse_reads = []
      attachments.each do |attachment|
        if attachment.metadata['direction'] == 'forward'
          forward_reads << attachment
        elsif attachment.metadata['direction'] == 'reverse'
          reverse_reads << attachment
        end
      end

      if forward_reads.length != reverse_reads.length
        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.incorrect_file_pairs')
      end

      [forward_reads, reverse_reads]
    end

    # Gets the blobs for the passed in attachments
    def retrieve_attachment_blobs(attachments)
      blobs = []
      attachments.map do |attachment|
        blobs << attachment.file.blob
      end
      blobs
    end
  end
end
