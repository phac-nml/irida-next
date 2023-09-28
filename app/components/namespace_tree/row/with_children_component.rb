# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of a group row that has children
    class WithChildrenComponent < Viral::Component
      # rubocop:disable Metrics/ParameterLists
      def initialize(group:, children:, type:, path: nil, path_args: {}, collapsed: false)
        @group = group
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
