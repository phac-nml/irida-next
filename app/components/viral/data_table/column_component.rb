# frozen_string_literal: true

module Viral
  module DataTable
    # Component responsible for specific column data of DataTableComponent
    class ColumnComponent < Viral::Component
      attr_reader :title

      STICKY_CLASSES = {
        left: {
          header: 'sticky left-0 bg-slate-50 dark:bg-slate-700 z-10 ',
          body: 'sticky left-0 bg-slate-50 dark:bg-slate-900 z-10'
        },
        left_fixed_index_zero: {
          header: 'sticky left-0 min-w-56 max-w-56 bg-slate-50 dark:bg-slate-700 z-10',
          body: 'sticky left-0 min-w-56 max-w-56 bg-slate-50 dark:bg-slate-800 z-10'
        },
        left_fixed_index_one: {
          header: 'sticky left-56 bg-slate-50 dark:bg-slate-700 z-10',
          body: 'sticky left-56 bg-slate-50 dark:bg-slate-800 z-10'
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

      def header_cell_arguments
        {
          classes:
          class_names('px-3 py-3',
                      @system_arguments[:sticky_key] && STICKY_CLASSES[@system_arguments[:sticky_key]][:header])
        }
      end

      def body_cell_arguments
        {
          classes:
          class_names('px-3 py-3',
                      @system_arguments[:sticky_key] && STICKY_CLASSES[@system_arguments[:sticky_key]][:body])
        }
      end

      def call(row)
        @block.call(row)
      end
    end
  end
end
