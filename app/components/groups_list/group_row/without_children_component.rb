# frozen_string_literal: true

module GroupsList
  module GroupRow
    # Component for the contents of a group row that has no children
    class WithoutChildrenComponent < ViewComponent::Base
      def initialize(group:, path: nil, path_args: {})
        @group = group
        @path = path
        @path_args = path_args
      end
    end
  end
end
