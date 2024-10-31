# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of NamespaceTree row
    class RowContentsComponent < Viral::Component
      # rubocop:disable Metrics/ParameterLists
      def initialize(namespace:, path: nil, path_args: {}, collapsed: false, icon_size: :small, search_params: nil)
        @namespace = namespace
        @path = path
        @path_args = path_args
        @collapsed = collapsed
        @icon_size = icon_size
        @search_params = search_params
      end

      # rubocop:enable Metrics/ParameterLists
    end
  end
end
