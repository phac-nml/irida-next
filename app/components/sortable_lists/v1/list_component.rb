# frozen_string_literal: true

module SortableLists
  module V1
    # This component creates the individual lists for the sortable_lists component.
    class ListComponent < ::Component
      attr_reader :id, :title, :list_items, :required, :available_list, :selected_list, :instructions_id

      # rubocop:disable Metrics/ParameterLists

      def initialize(id: nil, title: nil, list_items: [], required: false, instructions_id: nil, **system_arguments)
        @id = id
        @title = title
        @list_items = list_items
        @required = required
        @instructions_id = instructions_id
        @system_arguments = system_arguments
        @system_arguments[:list_classes] =
          class_names('border border-slate-300 rounded-lg block dark:bg-slate-800 dark:border-slate-600 max-h-[225px]
          min-h-[225px] overflow-y-auto')
        @system_arguments[:container_classes] =
          class_names('text-slate-900 dark:text-white grow block mb-1 text-sm font-medium')
        @available_list = id.include?('available')
        @selected_list = id.include?('selected')
      end

      def add_remove_controls
        [id, counterpart_list_id].compact.join(' ')
      end

      def described_by_ids
        [instructions_id, (required ? "#{id}-required" : nil)].compact.join(' ')
      end

      private

      def counterpart_list_id
        if available_list && id.match?(/available/i)
          id.sub(/available/i, 'selected')
        elsif selected_list && id.match?(/selected/i)
          id.sub(/selected/i, 'available')
        end
      end

      # rubocop:enable Metrics/ParameterLists
    end
  end
end
