# frozen_string_literal: true

module Viral
  module SortableList
    # A component representing an item in a sortable list.
    # This component is used to render individual list items.
    class ListItemComponent < Viral::Component
      attr_reader :list_item

      def initialize(list_item:)
        @list_item = list_item
      end
    end
  end
end
