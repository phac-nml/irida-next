# frozen_string_literal: true

module SortableLists
  module V1
    # A component representing an item in a sortable list.
    class ListItemComponent < ::Component
      attr_reader :list_item, :interactive

      def initialize(list_item:, interactive: true)
        @id = "list_item_#{SecureRandom.uuid}"
        @list_item = list_item
        @interactive = interactive
      end
    end
  end
end
