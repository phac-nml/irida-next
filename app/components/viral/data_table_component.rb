# frozen_string_literal: true

module Viral
  # Table Component used to display data
  class DataTableComponent < Viral::Component
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
        #   args[:data][:'selection-action-button-outlet'] = '.action-button'
        # end
      end
    end

    def wrapper_arguments
      {
        tag: 'div',
        classes: class_names('table-container flex flex-col shrink min-h-0')
      }
    end

    def row_arguments(data)
      { tag: 'tr' }.tap do |args|
        args[:classes] =
          class_names('bg-white dark:bg-slate-800', 'border-b border-slate-200 dark:border-slate-700')
        args[:id] = data.respond_to?(:to_key) ? dom_id(data) : "non_ar_#{data.object_id}"
      end
    end

    def render_cell(**arguments, &)
      render(Viral::BaseComponent.new(**arguments), &)
    end
  end
end
