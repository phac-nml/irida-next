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
      color = type == 'direction' ? nil : get_color(type, attachment)
      case type
      when 'direction'
        direction = attachment.metadata.key?('direction') ? get_direction(attachment.metadata['direction']) : nil
        { type: 'direction', color:, label: direction }
      when 'format'
        { type: 'format', color:,
          label: attachment.metadata['format'] }
      when 'type'
        { type: 'type', color:, label: attachment.metadata['type'] }
      end
    end

    def get_direction(direction)
      return 'forward' if direction == 'forward'

      'reverse'
    end

    def get_color(type, attachment)
      if type == 'format'
        COLORS[type.to_sym][attachment.metadata['format'].to_sym]
      elsif type == 'type'
        attachment.metadata.key?('type') ? COLORS[type.to_sym][attachment.metadata['type'].to_sym] : nil
      end
    end
  end
end
