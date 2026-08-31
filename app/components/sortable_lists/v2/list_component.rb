# frozen_string_literal: true

module SortableLists
  module V2
    # This component creates an individual checkbox list for the sortable lists component.
    class ListComponent < ::Component
      attr_reader :id, :title, :list_items, :required, :available_list, :selected_list, :instructions_id,
                  :list_role, :counterpart_list_id, :interactive

      # rubocop:disable Metrics/ParameterLists
      def initialize(
        id: nil,
        title: nil,
        list_items: [],
        required: false,
        describedby: nil,
        instructions_id: nil,
        list_role: nil,
        counterpart_list_id: nil,
        interactive: true,
        **system_arguments
      )
        @id = id
        @title = title
        @list_items = list_items
        @required = required
        @describedby = describedby
        @instructions_id = instructions_id
        @list_role = normalize_list_role(list_role, id)
        @counterpart_list_id = counterpart_list_id
        @interactive = interactive
        @system_arguments = build_system_arguments(system_arguments)
        @available_list, @selected_list = list_membership(@list_role)
      end
      # rubocop:enable Metrics/ParameterLists

      def add_remove_controls
        [id, resolved_counterpart_list_id].compact.join(' ')
      end

      def described_by_ids
        [instructions_id, @describedby, (aria_required ? "#{id}-required" : nil)].compact.join(' ')
      end

      def aria_required
        required && selected_list
      end

      private

      def resolved_counterpart_list_id
        counterpart_list_id.presence || inferred_counterpart_list_id
      end

      def normalize_list_role(role, list_id)
        normalized_role = role&.to_sym
        return normalized_role if %i[available selected].include?(normalized_role)

        return :available if list_id&.match?(/available/i)
        return :selected if list_id&.match?(/selected/i)

        nil
      end

      def inferred_counterpart_list_id
        return if id.blank?

        if available_list && id.match?(/available/i)
          id.sub(/available/i, 'selected')
        elsif selected_list && id.match?(/selected/i)
          id.sub(/selected/i, 'available')
        end
      end

      def build_system_arguments(system_arguments)
        system_arguments.tap do |arguments|
          arguments[:list_classes] = class_names(
            'border border-slate-300 rounded-lg block dark:bg-slate-800 dark:border-slate-600 ' \
            'max-h-[225px] min-h-[225px] overflow-y-auto'
          )
          arguments[:container_classes] = class_names(
            'text-slate-900 dark:text-white grow block mb-1 text-sm font-medium'
          )
        end
      end

      def list_membership(role)
        [role == :available, role == :selected]
      end
    end
  end
end
