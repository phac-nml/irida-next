# frozen_string_literal: true

module NamespaceTree
  module Row
    # Component for the contents of NamespaceTree row
    class RowContentsComponent < Viral::Component
      include NamespacePathHelper

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

      def avatar_icon
        if @namespace.type == 'Group'
          :squares_2x2
        elsif @namespace.type == 'Project'
          :rectangle_stack
        end
      end
    end
  end
end
