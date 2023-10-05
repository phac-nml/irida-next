# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of a namespace row that has children
    class WithChildrenComponent < Viral::Component
      # rubocop:disable Metrics/ParameterLists
      def initialize(namespace:, children:, type:, path: nil, path_args: {}, collapsed: false)
        @namespace = namespace
        @children = children
        @type = type
        @path = path
        @path_args = path_args
        @collapsed = collapsed
      end

      # rubocop:enable Metrics/ParameterLists
    end
  end
end
