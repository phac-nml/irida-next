# frozen_string_literal: true

module SortableLists
  module V2
    # A component representing an item in a sortable checkbox list.
    class ListItemComponent < ::Component
      attr_reader :list_item, :interactive, :checkbox_id

      def initialize(list_item:, list_id:, interactive: true)
        @checkbox_id = "#{list_id.parameterize}-item-#{SecureRandom.hex(6)}"
        @list_item = list_item
        @interactive = interactive
      end
    end
  end
end
