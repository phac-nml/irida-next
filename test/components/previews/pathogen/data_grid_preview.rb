# frozen_string_literal: true

module Pathogen
  # @label Data Grid
  class DataGridPreview < ViewComponent::Preview
    # @label Basic
    def basic
      render Pathogen::DataGridComponent.new(
        caption: 'Sample inventory (sticky columns preview)',
        sticky_columns: 2,
        rows: ROWS
      ) do |grid|
        grid.with_column('Sample ID', key: :sample_id, width: 140)
        grid.with_column('Name', key: :name)
        grid.with_column('Organism', key: :organism)
        grid.with_column('Collected', key: :collected_at)
        grid.with_column('Notes', key: :notes)
      end
    end

    # @label Without Caption
    def without_caption
      render Pathogen::DataGridComponent.new(
        sticky_columns: 1,
        rows: [
          { id: 'S-001', name: 'Sample one', status: 'Active' },
          { id: 'S-002', name: 'Sample two', status: 'Pending' }
        ]
      ) do |grid|
        grid.with_column('ID', key: :id, width: 120)
        grid.with_column('Name', key: :name)
        grid.with_column('Status', key: :status)
      end
    end

    # @label No Sticky Columns
    def no_sticky_columns
      render Pathogen::DataGridComponent.new(
        caption: 'Non-sticky grid',
        sticky_columns: 0,
        rows: [
          { sample_id: 'SAM-0101', name: 'Forest isolate', organism: 'E. coli' },
          { sample_id: 'SAM-0102', name: 'Wetland isolate', organism: 'Salmonella enterica' }
        ]
      ) do |grid|
        grid.with_column('Sample ID', key: :sample_id)
        grid.with_column('Name', key: :name)
        grid.with_column('Organism', key: :organism)
      end
    end

    # @label Custom Cells
    def custom_cells
      render Pathogen::DataGridComponent.new(
        caption: 'Custom cell rendering',
        sticky_columns: 1,
        rows: [
          { id: 'S-101', name: 'Aurora basin', status: 'Active', collected_at: '2026-01-19' },
          { id: 'S-102', name: 'Prairie creek', status: 'Pending', collected_at: '2026-01-27' }
        ]
      ) do |grid|
        grid.with_column('ID', key: :id, width: 120)
        grid.with_column('Name') { |row| tag.strong(row[:name]) }
        grid.with_column('Status') { |row| tag.span(row[:status], title: "Status: #{row[:status]}") }
        grid.with_column('Collected') { |row| tag.time(row[:collected_at]) }
      end
    end

    ROWS = [
      {
        sample_id: 'SAM-0001',
        name: 'Northern lake isolate with extended name',
        organism: 'Listeria monocytogenes',
        collected_at: '2026-01-18',
        notes: 'Text spacing test: long content stays on one line to demonstrate auto column sizing.'
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
        notes: 'Additional notes to showcase overflow behavior and sticky boundary.'
      }
    ].freeze
  end
end
