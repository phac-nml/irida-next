# frozen_string_literal: true

module Viral
  # Table Component used to display data
  class DataTableComponent < Viral::Component
    # renders_many :columns, Viral::DataTable::ColumnComponent
    renders_many :columns, lambda { |title, **system_arguments, &block|
      Viral::DataTable::ColumnComponent.new(title, **system_arguments, &block)
    }
    def initialize(
      data,
      id: '',
      **system_arguments
    )
      @data = data
      @id = id
      @system_arguments = system_arguments
    end

    def system_arguments
      { tag: 'div' }.deep_merge(@system_arguments).tap do |args|
        args[:id] = @id
        args[:classes] = class_names(args[:classes], 'overflow-auto scrollbar')
        # possibly to be used once implemented into tables with selection
        # if @abilities[:select]
        #   args[:data] ||= {}
        #   args[:data][:controller] = 'selection'
        #   args[:data][:'selection-total-value'] = @pagy.count
        #   args[:data][:'selection-action-link-outlet'] = '.action-link'
        # end
      end
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container flex flex-col shrink min-h-0 data-turbo-temporary'),
        scope: 'col'
      }
    end

    def row_arguments(data)
      { tag: 'tr' }.tap do |args|
        args[:classes] = class_names('bg-white', 'border-b', 'dark:bg-slate-800', 'dark:border-slate-700')
        args[:id] = data.id
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end
  end
end
