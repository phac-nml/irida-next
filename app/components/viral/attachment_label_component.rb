# frozen_string_literal: true

module Viral
  # Viral component for attachments table colored labels
  class AttachmentLabelComponent < Viral::Component
    attr_reader :label

    def initialize(type:, attachment:, span_row: false)
      @label = attachment_label(type, attachment, span_row)
    end

    private

    # rubocop:disable Metrics/MethodLength
    def attachment_label(type, attachment, span_row)
      case type
      when 'direction'
        direction = attachment.metadata.key?('direction') ? get_direction(attachment.metadata['direction']) : nil
        {
          type: 'direction',
          color: 'none',
          label: direction,
          span: span_row
        }
      when 'format'
        {
          type: 'format',
          color: 'none',
          label: attachment.metadata['format'],
          span: span_row
        }
      when 'type'
        {
          type: 'type',
          color: 'none',
          label: attachment.metadata['type'],
          span: span_row
        }
      end
    end

    def get_direction(direction)
      return 'forward' if direction == 'forward'

      'reverse'
    end
  end
end
