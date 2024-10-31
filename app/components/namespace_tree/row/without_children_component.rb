# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of a namespace row that has no children
    class WithoutChildrenComponent < Viral::Component
      def initialize(namespace:, path: nil, path_args: {}, icon_size: :small, search_params: nil)
        @namespace = namespace
        @path = path
        @path_args = path_args
        @icon_size = icon_size
        @search_params = search_params
      end
    end
  end
end
