# frozen_string_literal: true

module Viral
  # Component for rendering a data table
  class DataTableComponent < Viral::Component
    ALIGNMENT_DEFAULT = :top
    ALIGNMENT_OPTIONS = %i[top bottom middle baseline].freeze

    renders_many :columns, lambda { |title, **system_arguments, &block|
      Viral::DataTable::ColumnComponent.new(title, **system_arguments, &block)
    }
    renders_one :footer

    def initialize(
      data,
      hoverable: true,
      vertical_alignment: ALIGNMENT_DEFAULT,
      totals_in_header: false,
      totals_in_footer: false,
      increased_density: false,
      **system_arguments
    )
      @data = data
      @hoverable = hoverable
      @vertical_alignment = vertical_alignment
      @totals_in_header = totals_in_header
      @totals_in_footer = totals_in_footer
      @increased_density = increased_density
      @system_arguments = system_arguments
    end

    def system_arguments
      { tag: 'div' }.deep_merge(@system_arguments).tap do |_arguments|
        args[:classes] = class_names(args[:classes],
                                     'bg-white rounded-lg shadow')
      end
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('relative overflow-x-auto shadow-md sm:rounded-lg')
      }
    end

    def row_arguments
      {
        tag: 'tr',
        classes: class_names('flex flex-col')
      }
    end

    def render_cell(**, &)
      render(Viral::DataTable::CellComponent.new(vertical_alignment: @vertical_alignment, **), &)
    end
  end
end
