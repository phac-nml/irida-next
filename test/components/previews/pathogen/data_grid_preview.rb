# frozen_string_literal: true

module Pathogen
  # @label Data Grid
  class DataGridPreview < ViewComponent::Preview
    # @label Basic
    def basic
      render Pathogen::DataGridComponent.new(
        caption: 'Sample inventory (sticky columns preview)',
        sticky_columns: 2,
        columns: COLUMNS,
        rows: ROWS
      )
    end

    # @label Without Caption
    def without_caption
      render Pathogen::DataGridComponent.new(
        sticky_columns: 1,
        columns: [
          { key: :id, label: 'ID', width: 120 },
          { key: :name, label: 'Name', width: 240 },
          { key: :status, label: 'Status', width: 160 }
        ],
        rows: [
          { id: 'S-001', name: 'Sample one', status: 'Active' },
          { id: 'S-002', name: 'Sample two', status: 'Pending' }
        ]
      )
    end

    # @label No Sticky Columns
    def no_sticky_columns
      render Pathogen::DataGridComponent.new(
        caption: 'Non-sticky grid',
        sticky_columns: 0,
        columns: [
          { key: :sample_id, label: 'Sample ID', width: 140 },
          { key: :name, label: 'Name', width: 220 },
          { key: :organism, label: 'Organism', width: 220 }
        ],
        rows: [
          { sample_id: 'SAM-0101', name: 'Forest isolate', organism: 'E. coli' },
          { sample_id: 'SAM-0102', name: 'Wetland isolate', organism: 'Salmonella enterica' }
        ]
      )
    end

    COLUMNS = [
      { key: :sample_id, label: 'Sample ID', width: 140 },
      { key: :name, label: 'Name', width: 220 },
      { key: :organism, label: 'Organism', width: 220 },
      { key: :collected_at, label: 'Collected', width: 160 },
      { key: :notes, label: 'Notes', width: 320 }
    ].freeze

    ROWS = [
      {
        sample_id: 'SAM-0001',
        name: 'Northern lake isolate with extended name',
        organism: 'Listeria monocytogenes',
        collected_at: '2026-01-18',
        notes: 'Text spacing test: adjust letter and word spacing should wrap within sticky columns.'
      },
      {
        sample_id: 'SAM-0002',
        name: 'Coastal sediment sample',
        organism: 'Vibrio parahaemolyticus',
        collected_at: '2026-01-24',
        notes: 'Longer notes area to validate overlap handling when sticky columns are enabled.'
      },
      {
        sample_id: 'SAM-0003',
        name: 'Prairie field isolate',
        organism: 'Campylobacter jejuni',
        collected_at: '2026-01-30',
        notes: 'Additional notes to showcase wrapping behavior and sticky boundary.'
      }
    ].freeze
  end
end
