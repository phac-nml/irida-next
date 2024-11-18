# frozen_string_literal: true

module Viral
  module DataTable
    # Component responsible for specific column data of DataTableComponent
    class ColumnComponent < Viral::Component
      attr_reader :title

      STICKY_CLASSES = {
        left: {
          header: 'sticky left-0 bg-slate-50 dark:bg-slate-700 z-10 ',
          body: 'sticky left-0 bg-slate-50 dark:bg-slate-800 z-10'
        },
        sample_left_id: {
          header: 'sticky left-0 min-w-56 max-w-56 bg-slate-50 dark:bg-slate-700 z-10',
          body: 'sticky left-0 min-w-56 max-w-56 bg-slate-50 dark:bg-slate-800'
        },
        sample_left_name: {
          header: 'sticky left-56 bg-slate-50 dark:bg-slate-700 z-10 z-10',
          body: 'sticky left-56 bg-slate-50 dark:bg-slate-800'
        },
        right: {
          header: 'sticky right-0 bg-slate-50 dark:bg-slate-700 z-10',
          body: 'sticky right-0 bg-white dark:bg-slate-800 space-x-2 z-10'
        }
      }.freeze

      def initialize(
        title,
        **system_arguments,
        &block
      )
        @title = title
        @system_arguments = system_arguments
        @block = block
      end

      def system_arguments(is_header: nil)
        cell_type_key = is_header ? :header : :body
        {
          classes:
          class_names('px-3 py-3',
                      @system_arguments[:sticky_key] && STICKY_CLASSES[@system_arguments[:sticky_key]][cell_type_key])
        }
      end

      def call(row)
        @block.call(row)
      end
    end
  end
end
