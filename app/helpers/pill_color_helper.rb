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

  def find_pill_color_for_attachment(attachment, label_type)
    attachment.metadata.key?(label_type) ? ATTACHMENT_COLORS[label_type.to_sym][attachment.metadata[label_type].to_sym] : nil
  end
end
