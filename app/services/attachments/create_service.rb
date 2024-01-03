# frozen_string_literal: true

module Attachments
  # Service used to Create Attachments
  class CreateService < BaseService
    attr_accessor :attachable, :attachments

    def initialize(user = nil, attachable = nil, params = {})
      super(user, params)

      @attachable = attachable
      @attachments = []

      return unless params.key?(:files)

      params[:files].each do |file|
        @attachments << Attachment.new(attachable:, file:) if file.present?
      end
    end

    def execute # rubocop:disable Metrics/CyclomaticComplexity
      authorize! @attachable.project, to: :update_sample? if @attachable.instance_of?(Sample)

      @attachments.each(&:save)

      persisted_fastq_attachments = @attachments.select { |attachment| attachment.persisted? && attachment.fastq? }

      identify_illumina_paired_end_files(persisted_fastq_attachments) if persisted_fastq_attachments.count > 1

      unidentified_fastq_attachments = persisted_fastq_attachments.reject do |attachment|
        attachment.metadata['type'] == 'illumina_pe'
      end

      identify_paired_end_files(unidentified_fastq_attachments) if unidentified_fastq_attachments.count > 1

      @attachments
    end

    private

    def identify_illumina_paired_end_files(attachments)
      # auto-vivify hash, as found on stack overflow http://stackoverflow.com/questions/5878529/how-to-assign-hashab-c-if-hasha-doesnt-exist
      illumina_pe = Hash.new { |h, k| h[k] = {} }

      # identify illumina pe attachments based on illumina fastq filename convention
      # https://support.illumina.com/help/BaseSpace_OLH_009008/Content/Source/Informatics/BS/NamingConvention_FASTQ-files-swBS.htm
      attachments.each do |att|
        unless /^(?<sample_name>.+_[^_]+_L[0-9]{3})_R(?<region>[1-2])_(?<set_number>[0-9]{3})\./ =~ att.filename.to_s
          next
        end

        case region
        when '1'
          illumina_pe["#{sample_name}_#{set_number}"]['forward'] = att
        when '2'
          illumina_pe["#{sample_name}_#{set_number}"]['reverse'] = att
        end
      end

      # assign metadata to detected illumina pe files that contain fwd and rev
      assign_metadata(illumina_pe, 'illumina_pe')
    end

    def identify_paired_end_files(attachments) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/MethodLength
      # auto-vivify hash, as found on stack overflow http://stackoverflow.com/questions/5878529/how-to-assign-hashab-c-if-hasha-doesnt-exist
      pe = Hash.new { |h, k| h[k] = {} }

      # identify pe attachments based on fastq filename convention
      attachments.each do |att|
        next unless /^(?<sample_name>.+_)(?<region>R?[1-2]|[FfRr])\./ =~ att.filename.to_s

        case region
        when '1'
          pe["#{sample_name}_1-2"]['forward'] = att
        when 'R1'
          pe["#{sample_name}_R1-R2"]['forward'] = att
        when 'F'
          pe["#{sample_name}_F-R"]['forward'] = att
        when 'f'
          pe["#{sample_name}_f-r"]['forward'] = att
        when '2'
          pe["#{sample_name}_1-2"]['reverse'] = att
        when 'R2'
          pe["#{sample_name}_R1-R2"]['reverse'] = att
        when 'R'
          pe["#{sample_name}_F-R"]['reverse'] = att
        when 'r'
          pe["#{sample_name}_f-r"]['reverse'] = att
        end
      end

      # assign metadata to detected pe files that contain fwd and rev
      assign_metadata(pe, 'pe')
    end

    def assign_metadata(paired_ends, type)
      paired_ends.each do |_key, pe_attachments|
        next unless pe_attachments.key?('forward') && pe_attachments.key?('reverse')

        fwd_metadata = {
          associated_attachment_id: pe_attachments['reverse'].id, type:, direction: 'forward'
        }

        pe_attachments['forward'].update(metadata: pe_attachments['forward'].metadata.merge(fwd_metadata))

        rev_metadata = {
          associated_attachment_id: pe_attachments['forward'].id, type:, direction: 'reverse'
        }

        pe_attachments['reverse'].update(metadata: pe_attachments['reverse'].metadata.merge(rev_metadata))
      end
    end
  end
end
