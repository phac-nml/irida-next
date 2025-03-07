# frozen_string_literal: true

# Route helper that converts Route object into context_crumbs
module PillColorHelper
  ATTACHMENT_COLORS = {
    format: {
      fasta: 'blue',
      fastq: 'green',
      text: 'orange',
      csv: 'fuchsia',
      image: 'purple',
      tsv: 'lime',
      json: 'sky',
      genbank: 'teal',
      spreadsheet: 'yellow',
      unknown: 'slate'
    },
    type: {
      assembly: 'pink',
      illumina_pe: 'purple',
      pe: 'amber'
    }
  }.freeze

  def find_pill_color_for_attachment(attachment, label_type)
    return unless attachment[:metadata].key?(label_type)

    ATTACHMENT_COLORS[label_type.to_sym][attachment[:metadata][label_type].to_sym]
  end

  def find_pill_color_for_state(state)
    pill_color = :blue
    if %w[initial prepared].include?(state)
      pill_color = :slate
    elsif %w[canceling canceled].include?(state)
      pill_color = :yellow
    elsif state == 'error'
      pill_color = :red
    elsif state == 'completed'
      pill_color = :green
    end
    pill_color
  end
end
