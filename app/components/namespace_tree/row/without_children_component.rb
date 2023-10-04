# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of a namespace row that has no children
    class WithoutChildrenComponent < Viral::Component
      def initialize(namespace:, path: nil, path_args: {})
        @namespace = namespace
        @path = path
        @path_args = path_args
      end
    end
  end
end
