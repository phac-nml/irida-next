# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of NamespaceTree row
    class RowContentsComponent < Viral::Component
      def initialize(namespace:, path: nil, path_args: {}, collapsed: false, sample_count: 0)
        @namespace = namespace
        @path = path
        @path_args = path_args
        @collapsed = collapsed
        @sample_count = sample_count
      end
    end
  end
end
