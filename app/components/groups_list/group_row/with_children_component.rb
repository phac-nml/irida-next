# frozen_string_literal: true

module GroupsList
  module GroupRow
    # Component for the contents of a group row that has children
    class WithChildrenComponent < ViewComponent::Base
      def initialize(group:, path: nil, path_args: {}, collapsed: false)
        @group = group
        @path = path
        @path_args = path_args
        @collapsed = collapsed
      end
    end
  end
end
