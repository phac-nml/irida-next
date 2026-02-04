# frozen_string_literal: true

module Pathogen
  # DataGrid component for rendering accessible tabular data with sticky columns.
  #
  # CSS dependency: app/assets/stylesheets/pathogen/data_grid.css
  class DataGridComponent < Pathogen::Component
    attr_reader :columns, :rows

    def initialize(columns:, rows:, caption: nil, sticky_columns: 0, **system_arguments)
      @columns = normalize_columns(columns, sticky_columns)
      @rows = rows
      @caption = caption
      @caption_id = @caption.present? ? self.class.generate_id(base_name: 'data-grid-caption') : nil
      @system_arguments = system_arguments
      @system_arguments[:class] = class_names(@system_arguments[:class], 'pathogen-data-grid')
    end

    def caption?
      @caption.present?
    end

    def table_attributes
      return { class: 'pathogen-data-grid__table' } unless @caption_id

      { class: 'pathogen-data-grid__table', aria: { describedby: @caption_id } }
    end

    def header_cell_attributes(column)
      attributes_for(column, header: true).merge(scope: 'col')
    end

    def body_cell_attributes(column)
      attributes_for(column, header: false)
    end

    def cell_value_for(row, column, index)
      return row[index] if row.is_a?(Array)
      return row[column[:key]] if row.key?(column[:key])

      row[column[:key].to_s]
    end

    private

    def normalize_columns(columns, sticky_columns)
      sticky_offset = 0

      columns.map.with_index do |column, index|
        column_config = base_column_config(column)
        column_config[:width] = normalize_width(column_config[:width])

        if sticky_column?(column_config, index, sticky_columns)
          column_config[:sticky] = true
          column_config[:sticky_left] ||= sticky_offset
          sticky_offset += parse_px(column_config[:width]) if column_config[:width]
        end

        column_config
      end
    end

    def normalize_width(width)
      return if width.blank?
      return "#{width}px" if width.is_a?(Numeric)

      width
    end

    def parse_px(width)
      return unless width

      match = width.to_s.strip.match(/\A(\d+(?:\.\d+)?)px\z/)
      return unless match

      match[1].to_f
    end

    def attributes_for(column, header:)
      classes = ['pathogen-data-grid__cell']
      classes << (header ? 'pathogen-data-grid__cell--header' : 'pathogen-data-grid__cell--body')
      classes << 'pathogen-data-grid__cell--sticky' if column[:sticky]
      classes << "pathogen-data-grid__cell--align-#{column[:align]}" if column[:align]

      styles = []
      styles << "--pathogen-data-grid-col-width: #{column[:width]};" if column[:width]
      styles << "--pathogen-data-grid-sticky-left: #{column[:sticky_left]}px;" if column[:sticky]

      { class: class_names(*classes), style: styles.join(' ') }
    end

    def base_column_config(column)
      column_config = column.symbolize_keys
      column_config[:key] ||= column_config[:id]
      column_config[:label] ||= column_config[:key].to_s.humanize
      column_config
    end

    def sticky_column?(column_config, index, sticky_columns)
      return column_config[:sticky] if column_config.key?(:sticky)

      index < sticky_columns
    end
  end
end
