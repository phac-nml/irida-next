# frozen_string_literal: true

# Route helper that converts Route object into context_crumbs
module PillColorHelper
  TABLE_CONTENT_COLORS = {
    'workflow_executions' => {
      'initial' => :slate,
      'prepared' => :slate,
      'submitted' => :blue,
      'running' => :blue,
      'completing' => :blue,
      'completed' => :green,
      'error' => :red,
      'canceling' => :yellow,
      'canceled' => :yellow
    },
    'data_exports' => {
      'processing' => :slate,
      'ready' => :green
    }
  }.freeze

  ATTACHMENT_COLORS = {
    format: {
      fasta: 'blue',
      fastq: 'green',
      text: 'orange',
      csv: 'fuchsia',
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
    return unless attachment.metadata.key?(label_type)

    ATTACHMENT_COLORS[label_type.to_sym][attachment.metadata[label_type].to_sym]
  end

  def retrieve_pill_color(data_type, pill_content)
    TABLE_CONTENT_COLORS[data_type][pill_content]
  end
end
