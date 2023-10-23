# frozen_string_literal: true

module Viral
  # Viral component for attachments table colored labels
  class AttachmentLabelComponent < Viral::Component
    attr_reader :label

    COLORS = {
      format: {
        fasta: 'bg-blue-100 text-blue-800 text-base font-medium
        mr-2 px-2.5 py-0.5 rounded-full dark:bg-blue-900 dark:text-blue-300 text-center',
        fastq: 'bg-green-100 text-green-800 text-base font-medium
        mr-2 px-2.5 py-0.5 rounded-full dark:bg-green-900 dark:text-green-300 text-center',
        unknown: 'bg-gray-100 text-gray-800 text-base font-medium
        mr-2 px-2.5 py-0.5 rounded-full dark:bg-gray-700 dark:text-gray-300 text-center'
      },
      type: {
        assembly: 'bg-pink-100 text-pink-800 text-base font-medium
        mr-2 px-2.5 py-0.5 rounded-full dark:bg-pink-900 dark:text-pink-300 text-center',
        illumina_pe: 'bg-purple-100 text-purple-800 text-base font-medium
        mr-2 px-2.5 py-0.5 rounded-full dark:bg-purple-900 dark:text-purple-300 text-center'
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
