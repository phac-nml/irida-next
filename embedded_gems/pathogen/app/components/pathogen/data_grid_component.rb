# frozen_string_literal: true

module Pathogen
  # DataGrid component for rendering accessible tabular data with sticky columns.
  #
  # CSS dependency: app/assets/stylesheets/pathogen/data_grid.css
  class DataGridComponent < Pathogen::Component
    renders_many :columns, lambda { |label, **system_arguments, &block|
      Pathogen::DataGrid::ColumnComponent.new(label, **system_arguments, &block)
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

      { class: 'pathogen-data-grid__table', aria: { describedby: @caption_id } }
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
