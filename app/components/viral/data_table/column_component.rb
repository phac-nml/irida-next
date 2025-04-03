# frozen_string_literal: true

module Viral
  module DataTable
    # Component responsible for specific column data of DataTableComponent
    class ColumnComponent < Viral::Component
      attr_reader :title

      STICKY_CLASSES = {
        left: {
          header: '@2xl:sticky left-0 bg-slate-50 dark:bg-slate-700 z-10 ',
          body: '@2xl:sticky left-0 bg-slate-50 dark:bg-slate-900 z-10'
        },
        left_fixed_index_zero: {
          header: '@2xl:sticky left-0 min-w-56 max-w-56 bg-slate-50 dark:bg-slate-700 z-10',
          body: '@2xl:sticky left-0 min-w-56 max-w-56 bg-slate-50 dark:bg-slate-800 z-10'
        },
        left_fixed_index_one: {
          header: 'sticky left-56 bg-slate-50 dark:bg-slate-700 z-10',
          body: 'sticky left-56 bg-slate-50 dark:bg-slate-800 z-10'
        },
        right: {
          header: '@4xl:sticky right-0 bg-slate-50 dark:bg-slate-700 z-10',
          body: '@4xl:sticky right-0 space-x-2 z-5 '
        }
      }.freeze

      def initialize(
        title,
        **system_arguments,
        &block
      )
        @title = title
        @system_arguments = system_arguments
        @system_arguments[:padding] = system_arguments[:padding] == false ? '' : 'py-3 px-3'
        @block = block
      end

      def header_cell_arguments
        {
          classes:
          class_names('px-3 py-3 bg-slate-100 dark:bg-slate-900 uppercase',
                      @system_arguments[:sticky_key] && STICKY_CLASSES[@system_arguments[:sticky_key]][:header])
        }
      end

      def body_cell_arguments
        {
          classes:
          class_names(@system_arguments[:padding],
                      @system_arguments[:sticky_key] && STICKY_CLASSES[@system_arguments[:sticky_key]][:body])
        }
      end

      delegate :call, to: :@block
    end
  end
end
