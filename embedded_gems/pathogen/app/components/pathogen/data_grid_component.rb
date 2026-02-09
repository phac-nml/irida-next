# frozen_string_literal: true

module Pathogen
  # DataGrid component for rendering accessible tabular data with sticky columns.
  #
  # == Public API
  #
  # @param rows [Array<Hash, Array>] The data rows to render.
  # @param caption [String, nil] Optional visual caption rendered above the table.
  #   When present, the table uses `aria-labelledby` to associate the caption.
  # @param sticky_columns [Integer] Number of leading columns to treat as sticky
  #   by default. Individual columns can override with `sticky: true/false`.
  # @param system_arguments [Hash] Additional HTML attributes for the outer wrapper.
  #
  # @example Basic usage
  #   <%= render Pathogen::DataGridComponent.new(rows: @rows, caption: "Samples") do |grid| %>
  #     <% grid.with_column("ID", key: :id, width: 120) %>
  #     <% grid.with_column("Name", key: :name, width: 240) %>
  #   <% end %>
  #
  # @example Custom cell rendering
  #   <%= render Pathogen::DataGridComponent.new(rows: @rows) do |grid| %>
  #     <% grid.with_column("Name") { |row| tag.strong(row[:name]) } %>
  #   <% end %>
  #
  # CSS dependency: pathogen/pathogen.css
  class DataGridComponent < Pathogen::Component
    # Renders an individual column definition for the grid.
    #
    # @param label [String] Column header label.
    # @param key [Symbol, String, nil] Hash key lookup when no block is provided.
    # @param width [Numeric, String, nil] Column width (numeric values become "px").
    # @param align [Symbol, String, nil] Alignment class suffix (e.g. :left, :center, :right).
    # @param sticky [Boolean, nil] Explicitly enable/disable sticky behavior for this column.
    # @param sticky_left [Numeric, nil] Left offset in pixels; can enable sticky without width.
    # @param system_arguments [Hash] Additional HTML attributes for the cell.
    # @yieldparam row [Hash, Array] Row data for the current cell.
    # @yieldparam index [Integer] Column index.
    # @return [Pathogen::DataGrid::ColumnComponent]
    renders_many :columns, lambda { |label, **system_arguments, &block|
      Pathogen::DataGrid::ColumnComponent.new(label: label, **system_arguments, &block)
    }
    attr_reader :rows

    def initialize(rows:, caption: nil, sticky_columns: 0, **system_arguments)
      @rows = rows
      @caption = caption
      @caption_id = @caption.present? ? self.class.generate_id(base_name: 'data-grid-caption') : nil
      @sticky_columns = sticky_columns
      @system_arguments = system_arguments
      @system_arguments[:class] = class_names(@system_arguments[:class], 'pathogen-data-grid')
    end

    def caption?
      @caption.present?
    end

    def table_attributes
      return { class: 'pathogen-data-grid__table' } unless @caption_id

      { class: 'pathogen-data-grid__table', aria: { labelledby: @caption_id } }
    end

    def before_render
      apply_column_defaults!
    end

    private

    def apply_column_defaults!
      sticky_offset = 0

      columns.each_with_index do |column, index|
        column.normalize_width!

        next unless sticky_column?(column, index)

        if column.width_px.nil? && column.sticky_left.nil?
          column.sticky = false
          next
        end

        column.sticky = true
        column.sticky_left ||= sticky_offset
        sticky_offset += column.width_px if column.width_px
      end
    end

    def sticky_column?(column, index)
      return column.sticky unless column.sticky.nil?

      index < @sticky_columns
    end
  end
end
