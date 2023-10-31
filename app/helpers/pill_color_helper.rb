# frozen_string_literal: true

# Route helper that converts Route object into context_crumbs
module PillColorHelper
  ATTACHMENT_COLORS = {
    format: {
      fasta: 'blue',
      fastq: 'green',
      unknown: 'gray'
    },
    type: {
      assembly: 'pink',
      illumina_pe: 'purple'
    }
  }.freeze

  def find_pill_color_for_format(attachment)
    attachment.metadata.key?('format') ? ATTACHMENT_COLORS[:format][attachment.metadata['format'].to_sym] : nil
  end

  def find_pill_color_for_type(attachment)
    attachment.metadata.key?('type') ? ATTACHMENT_COLORS[:type][attachment.metadata['type'].to_sym] : nil
  end
end
