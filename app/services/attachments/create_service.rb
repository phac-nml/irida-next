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

    def execute
      authorize! @attachable.project, to: :update_sample? if @attachable.instance_of?(Sample)

      @attachments.each(&:save)

      persisted_attachments = @attachments.select(&:persisted?)

      identify_illumina_pe(persisted_attachments&.select(&:fastq?))

      @attachments
    end

    private

    def identify_illumina_pe(attachments) # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize
      # auto-vivify hash, as found on stack overflow http://stackoverflow.com/questions/5878529/how-to-assign-hashab-c-if-hasha-doesnt-exist
      illumina_pe = Hash.new { |h, k| h[k] = {} }

      # identify illumina pe attachments based on illumina fastq filename convention
      # https://support.illumina.com/help/BaseSpace_OLH_009008/Content/Source/Informatics/BS/NamingConvention_FASTQ-files-swBS.htm
      attachments&.each do |attachment|
        if /^(?<sample_name>.+_[^_]+_L[0-9]{3})_R(?<region>[1-2])_(?<set_number>[0-9]{3})\./ =~ attachment.filename.to_s
          case region
          when '1'
            illumina_pe["#{sample_name}_#{set_number}"]['forward'] = attachment
          when '2'
            illumina_pe["#{sample_name}_#{set_number}"]['reverse'] = attachment
          end
        end
      end

      # assign metadata to detected illumina pe files that contain fwd and rev
      illumina_pe.each do |_key, pe_attachments|
        next unless pe_attachments.key?('forward') && pe_attachments.key?('reverse')

        fwd_metadata = {
          associated_attachment_id: pe_attachments['reverse'].id, type: 'illumina_pe', direction: 'forward'
        }

        pe_attachments['forward'].update(metadata: pe_attachments['forward'].metadata.merge(fwd_metadata))

        rev_metadata = {
          associated_attachment_id: pe_attachments['forward'].id, type: 'illumina_pe', direction: 'reverse'
        }

        pe_attachments['reverse'].update(metadata: pe_attachments['reverse'].metadata.merge(rev_metadata))
      end
    end
  end
end
