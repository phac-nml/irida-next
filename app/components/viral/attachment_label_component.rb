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

    def initialize(label_type:, attachment:)
      @label = attachment_label(label_type, attachment)
    end

    private

    def attachment_label(label_type, attachment)
      color = label_type == 'direction' ? nil : get_color(label_type, attachment)
      case label_type
      when 'direction'
        direction = attachment.metadata.key?('direction') ? get_direction(attachment.metadata['direction']) : nil
        { label_type: 'direction', color:, label: direction }
      when 'format'
        { label_type: 'format', color:,
          label: attachment.metadata['format'] }
      when 'type'
        { label_type: 'type', color:, label: attachment.metadata['type'] }
      end
    end

    def get_direction(direction)
      return 'forward' if direction == 'forward'

      'reverse'
    end

    def get_color(label_type, attachment)
      if label_type == 'format' && attachment.metadata.key?('format')
        COLORS[label_type.to_sym][attachment.metadata['format'].to_sym]
      elsif label_type == 'type'
        attachment.metadata.key?('type') ? COLORS[label_type.to_sym][attachment.metadata['type'].to_sym] : nil
      end
    end
  end
end
