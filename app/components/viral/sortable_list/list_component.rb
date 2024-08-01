# frozen_string_literal: true

module Viral
  module SortableList
    # This component creates the individual lists for the sortable_lists_component.
    class ListComponent < Viral::Component
      attr_reader :id, :group, :title, :list_items

      # If creating multiple lists to utilize the same list values, assign them the same group
      def initialize(id: nil, group: nil, title: nil, list_items: [], **system_arguments)
        @id = id
        @group = group
        @title = title
        @list_items = list_items
        @system_arguments = system_arguments
        @system_arguments[:list_classes] =
          class_names(
            'border border-slate-300 rounded-md block dark:bg-slate-800 dark:border-slate-600 max-h-[400px] min-h-[200px]',
            system_arguments[:list_classes]
          )
        @system_arguments[:container_classes] =
          class_names(
            'text-slate-900 dark:text-white',
            system_arguments[:container_classes]
          )
      end
    end
  end
end
