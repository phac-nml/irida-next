# frozen_string_literal: true

module Attachments
  # Service used to Concatenate Attachments
  class ConcatenationService < BaseService
    class AttachmentConcatenationError < StandardError
    end

    class AttachmentConcatenationFilenameError < StandardError
    end

    attr_accessor :attachable, :attachments, :concatenation_form

    def initialize(user = nil, concatenation_form = nil)
      super(user)
      @attachable = concatenation_form&.attachable
      @concatenation_form = concatenation_form
    end

    def execute
      # authorize if user can update sample
      authorize! attachable.project, to: :update_sample? if attachable.instance_of?(Sample)

      return [] unless concatenation_form.valid?

      attachments = concatenation_form.attachments

      validate_and_concatenate(attachments, concatenation_form.paired_end?)
    rescue Attachments::ConcatenationService::AttachmentConcatenationError => e
      concatenation_form.errors.add(:attachment_ids, e.message)
      []
    end

    private

    # Calls the validation, concatenate methods for the file type
    # If the user selects to delete the originals the originals
    # are deleted
    def validate_and_concatenate(attachments, is_paired_end)
      concatenated_attachments = []

      if is_paired_end
        validate_paired_end_files(attachments)
        concatenated_attachments = concatenate_paired_end_reads(attachments)
      else
        validate_single_end_files(attachments)
        concatenated_attachments = concatenate_single_end_reads(attachments)
      end

      # if option is selected then destroy the original files
      attachments.each(&:destroy) if concatenation_form.delete_originals

      concatenated_attachments
    end

    # Validates that the single end files are all the same type
    def validate_single_end_files(attachments) # rubocop:disable Naming/PredicateMethod
      attachments.each do |attachment|
        next unless attachment.metadata.key?('type')

        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.incorrect_file_types')
      end
      true
    end

    # Validates that the paired end files are all the same type
    def validate_paired_end_files(attachments) # rubocop:disable Naming/PredicateMethod
      attachments.each do |attachment|
        next if attachment.metadata.key?('type') && %w[illumina_pe pe].include?(attachments.first.metadata['type'])

        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.incorrect_file_types')
      end
      true
    end

    # Concatenates the single end reads into a single-end file
    def concatenate_single_end_reads(attachments)
      basename = concatenation_form.basename
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
      basename = concatenation_form.basename

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
      attachments.map { |attachment| attachment.file.blob }
    end
  end
end
