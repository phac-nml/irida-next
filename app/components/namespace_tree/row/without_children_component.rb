# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of a namespace row that has no children
    class WithoutChildrenComponent < Viral::Component
      def initialize(namespace:, path: nil, path_args: {})
        @namespace = namespace
        @path = path
        @path_args = path_args
        @sample_count = total_samples
      end

      def total_samples
        case @namespace.type
        when 'Group'
          @namespace.project_namespaces.sum { |project_namespace| project_namespace.project.samples.size }
        when 'Project'
          @namespace.project.samples.size
        when 'User'
          0
        end
      end
    end
  end
end
