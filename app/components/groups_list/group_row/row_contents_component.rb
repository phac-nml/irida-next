# frozen_string_literal: true

module GroupsList
  module GroupRow
    class RowContentsComponent < Viral::Component
      def initialize(group:, path: nil, path_args: {}, collapsed: false)
        @group = group
        @path = path
        @path_args = path_args
        @collapsed = collapsed
      end
    end
  end
end
