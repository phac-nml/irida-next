# frozen_string_literal: true

module SortableLists
  module V1
    # This component creates the individual lists for the sortable_lists component.
    class ListComponent < ::Component
      attr_reader :id, :group, :title, :list_items, :required, :available_list, :selected_list,
                  :show_actions, :empty_state_message

      # rubocop:disable Metrics/ParameterLists

      # If creating multiple lists to utilize the same list values, assign them the same group.
      def initialize(id: nil, group: nil, title: nil, list_items: [], required: false,
                     show_actions: true, empty_state_message: nil, **system_arguments)
        @id = id
        @group = group
        @title = title
        @list_items = list_items
        @required = required
        @show_actions = show_actions
        @empty_state_message = empty_state_message
        @system_arguments = system_arguments
        @system_arguments[:list_classes] =
          class_names('border border-slate-300 rounded-lg block dark:bg-slate-800 dark:border-slate-600 max-h-[225px]
          min-h-[225px] overflow-y-auto relative')
        @system_arguments[:container_classes] =
          class_names('text-slate-900 dark:text-white grow block mb-1 text-sm font-medium')
        @available_list = id.include?('available')
        @selected_list = id.include?('selected')
      end

      # rubocop:enable Metrics/ParameterLists
    end
  end
end
