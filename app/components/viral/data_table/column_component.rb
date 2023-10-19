# frozen_string_literal: true

module Viral
  module DataTable
    class ColumnComponent < Viral::Component
      SORT_DEFAULT = false
      SORT_OPTIONS = [false, :asc, :desc].freeze

      attr_reader :title, :numeric, :total, :sorted, :sort_url, :system_arguments

      def initialize(title, numeric: false, total: nil, sorted: SORT_DEFAULT, sort_url: nil, **system_arguments,
                     &block)
        @title = title
        @numeric = numeric
        @total = total
        @sorted = sorted
        @sort_url = sort_url
        @block = block
        @system_arguments = system_arguments
      end

      def call(row)
        @block.call(row)
      end
    end
  end
end
