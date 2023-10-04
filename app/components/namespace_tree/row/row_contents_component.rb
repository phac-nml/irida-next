# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of NamespaceTree row
    class RowContentsComponent < Viral::Component
      def initialize(namespace:, path: nil, path_args: {}, collapsed: false)
        @namespace = namespace
        @path = path
        @path_args = path_args
        @collapsed = collapsed
      end
    end
  end
end
