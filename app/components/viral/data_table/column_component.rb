# frozen_string_literal: true

module Viral
  module DataTable
    # Component responsible for specific column attributes of DataTableComponent
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

      def system_arguments
        {
          classes: class_names('px-3 py-3')
        }
      end

      def call(row)
        @block.call(row)
      end
    end
  end
end
