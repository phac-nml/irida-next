# frozen_string_literal: true

module Viral
  module DataTable
    # Component responsible for specific column data of DataTableComponent
    class ColumnComponent < Viral::Component
      attr_reader :title

      def initialize(
        title,
        **system_arguments,
        &block
      )
        @title = title
        @system_arguments = system_arguments
        @block = block
      end

      def system_arguments(column_title, is_header)
        additional_classes = if column_title == I18n.t('viral.data_table_component.header.action')
                               if is_header
                                 'bg-slate-50 dark:bg-slate-700 sticky right-0'
                               else
                                 'sticky right-0 bg-white dark:bg-slate-800 z-10 space-x-2'
                               end
                             end
        {
          classes:
          class_names('px-3 py-3', additional_classes)
        }
      end

      def call(row)
        @block.call(row)
      end
    end
  end
end
