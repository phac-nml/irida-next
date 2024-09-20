# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of a namespace row that has no children
    class WithoutChildrenComponent < Viral::Component
      def initialize(namespace:, path: nil, path_args: {})
        @namespace = namespace
        @path = path
        @path_args = path_args
        @sample_count = @namespace.type == 'Project' ? @namespace.project.samples.size : 0
      end
    end
  end
end
