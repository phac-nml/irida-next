# frozen_string_literal: true

module Viral
  module DataTable
    # Component responsible for specific column attributes of DataTableComponent
    class ColumnComponent < Viral::Component
      attr_reader :title, :show_link, :sticky, :sorted, :sort_url, :pill, :time_ago, :time, :metadata

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        title: '',
        show_link: false,
        sticky: false,
        pill: false,
        time_ago: false,
        time: false,
        metadata: false,
        **system_arguments
      )
        @title = title
        @show_link = show_link
        @sticky = sticky
        @pill = pill
        @time_ago = time_ago
        @time = time
        @metadata = metadata
        @system_arguments = system_arguments
      end
      # rubocop:enable Metrics/ParameterLists

      def system_arguments(table_type, index)
        if @sticky
          sticky_classes = if table_type == 'samples'
                             if index.zero?
                               'sticky left-0 min-w-56 max-w-56 z-10 bg-slate-50 dark:bg-slate-900'
                             else
                               'sticky left-56 z-10 bg-slate-50 dark:bg-slate-900'
                             end
                           else
                             'sticky left-0 bg-slate-50 dark:bg-slate-900'
                           end
        end
        {
          classes: class_names('px-3 py-3', @sticky && sticky_classes)
        }
      end
    end
  end
end
