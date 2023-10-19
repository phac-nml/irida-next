# frozen_string_literal: true

module Attachments
  # Service used to Concatenate Attachments
  class ConcatenationService < BaseService
    AttachmentConcatenationError = Class.new(StandardError)

    attr_accessor :attachable, :attachments, :concatenation_params

    def initialize(user = nil, attachable = nil, params = {})
      super(user, params)
      @attachable = attachable

      # single-end params: { concatenate_ids = [], basename: basefilename OPTIONAL,
      #                      delete_originals: true/false OPTIONAL
      #                      }
      # paired-end params: { concatenate_ids = [[],[]], basename: basefilename OPTIONAL,
      #                      delete_originals: true/false OPTIONAL
      #                      }
      @concatenation_params = params
    end

    def execute # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
      # authorize if user can update sample
      authorize! attachable.project, to: :update_sample? if attachable.instance_of?(Sample)

      concatenate_ids = concatenation_params[:concatenate_ids]

      unless concatenate_ids.all? { |i| i.is_a?(Integer) }
        # if multi-dimensional array of ids
        concatenate_ids = concatenate_ids.first + concatenate_ids.last
      end

      attachments = attachable.attachments.where(id: concatenate_ids, attachable:).order(:id)

      if !attachments.length == concatenate_ids.length
        raise AttachmentConcatenationError,
              I18n.t('services.attachments.concatenation.incorrect_attachable')
      end

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
    rescue Attachments::ConcatenationService::AttachmentConcatenationError => e
      attachable.errors.add(:base, e.message)
      attachable
    end

    private

    # Validates attachments to ensure they are of the correct type.
    # Files can only be concatenated as follows. No mixing of types:
    # Paired-end -> Paired-end
    # Single-end -> Single-end
    def validate_same_types(attachments, is_paired_end, is_single_end)
      valid_type = true

      attachments.each do |attachment|
        if is_single_end
          valid_type = !attachment.metadata.key?('type')
        elsif is_paired_end
          valid_type = attachment.metadata.key?('type')
        end
      end

      return if valid_type

      raise AttachmentConcatenationError,
            I18n.t('services.attachments.concatenation.incorrect_file_types')
    end

    # Concatenates the single end reads into a single-end file
    def concatenate_single_end_reads(attachments)
      basename = concatenation_params[:basename] || 'concatenated_file'

      begin
        dir = Dir.mktmpdir('concatenation')
        temp_file = Tempfile.new('cocatenatefile', [dir])

        attachments.each do |attachment|
          temp_file.write attachment.file.blob.download
        end
        temp_file.rewind

        new_attachment = attachable.attachments.build
        new_attachment.file.attach(io: temp_file.open, filename: "#{basename}_S1_L001_R1_001.fastq")
        new_attachment.save
      ensure
        FileUtils.remove_entry dir
      end
    end

    # Concatenates the paired-end reads into a multiple paired-end files
    def concatenate_paired_end_reads(forward_reads, reverse_reads) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      basename = concatenation_params[:basename] || 'concatenated_file'

      begin
        dir = Dir.mktmpdir('concatenation')
        temp_file_fwd = Tempfile.new('cocatenatefile_fwd', [dir])
        temp_file_rev = Tempfile.new('cocatenatefile_rev', [dir])

        forward_reads.each do |forward_read|
          temp_file_fwd.write forward_read.file.blob.download
        end
        temp_file_fwd.rewind

        reverse_reads.each do |reverse_read|
          temp_file_rev.write reverse_read.file.blob.download
        end
        temp_file_rev.rewind

        forward_reads_attachment = attachable.attachments.build
        forward_reads_attachment.file.attach(io: temp_file_fwd.open, filename: "#{basename}_S1_L001_R1_001.fastq")
        forward_reads_attachment.save

        reverse_reads_attachment = attachable.attachments.build
        reverse_reads_attachment.file.attach(io: temp_file_rev.open, filename: "#{basename}_S1_L001_R2_001.fastq")
        reverse_reads_attachment.save
      ensure
        # Remove the temp dir and it's contents
        FileUtils.remove_entry dir
      end
    end
  end
end
