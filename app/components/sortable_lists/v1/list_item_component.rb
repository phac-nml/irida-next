# frozen_string_literal: true

module SortableLists
  module V1
    # A component representing an item in a sortable list.
    class ListItemComponent < ::Component
      attr_reader :list_item

      def initialize(list_item:)
        @id = "list_item_#{SecureRandom.uuid}"
        @list_item = list_item
      end
    end
  end
end
