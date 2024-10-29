# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of NamespaceTree row
    class RowContentsComponent < Viral::Component
      def initialize(namespace:, path: nil, path_args: {}, collapsed: false, icon_size: :small)
        @namespace = namespace
        @path = path
        @path_args = path_args
        @collapsed = collapsed
        @icon_size = icon_size
      end
    end
  end
end
