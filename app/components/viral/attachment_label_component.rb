# frozen_string_literal: true

module Viral
  # Viral component for attachments table colored labels
  class AttachmentLabelComponent < Viral::Component
    attr_reader :label

    COLORS = {
      format: {
        fasta: 'bg-sky-400',
        fastq: 'bg-emerald-400',
        unknown: 'bg-gray-400'
      },
      type: {
        assembly: 'bg-orange-400',
        illumina_pe: 'bg-violet-400'
      }
    }.freeze

    def initialize(type:, attachment:)
      @label = attachment_label(type, attachment)
    end

    private

    def attachment_label(type, attachment)
      case type
      when 'direction'
        direction = attachment.metadata.key?('direction') ? get_direction(attachment.metadata['direction']) : nil
        { type: 'direction', color: nil, label: direction }
      when 'format'
        { type: 'format', color: COLORS[type.to_sym][attachment.metadata['format'].to_sym],
          label: attachment.metadata['format'] }
      when 'type'
        if attachment.metadata.key?('type')
          { type: 'type', color: COLORS[type.to_sym][attachment.metadata['type'].to_sym],
            label: attachment.metadata['type'] }
        else
          { type: 'type', color: nil, label: attachment.metadata['type'] }
        end
      end
    end

    def get_direction(direction)
      return 'forward' if direction == 'forward'

      'reverse'
    end
  end
end
