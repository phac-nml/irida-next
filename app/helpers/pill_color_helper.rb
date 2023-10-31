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
  def find_pill_color(type, subtype, item: nil)
    return unless type == 'attachment'

    item.metadata.key?(subtype) ? ATTACHMENT_COLORS[subtype.to_sym][item.metadata[subtype].to_sym] : nil
  end
end
