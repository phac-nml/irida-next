# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of NamespaceTree row
    class RowContentsComponent < Viral::Component
      # rubocop: disable Metrics/ParameterLists
      def initialize(namespace:, path: nil, path_args: {}, collapsed: false, sample_count: 0, icon_size: :small)
        @namespace = namespace
        @path = path
        @path_args = path_args
        @collapsed = collapsed
        @sample_count = sample_count
        @icon_size = icon_size
      end
      # rubocop: enable Metrics/ParameterLists
    end
  end
end
