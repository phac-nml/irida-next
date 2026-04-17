# frozen_string_literal: true

module SortableLists
  module V1
    # This component creates the sortable_lists.
    class Component < ::Component
      attr_reader :title, :description, :templates, :template_label,
                  :required, :aria_live_translations, :grouped_controls

      renders_many :lists, lambda { |id:, group:, title:, **system_arguments|
        empty_state_message = id.to_s.include?('selected') ? @selected_empty_state : nil
        SortableLists::V1::ListComponent.new(
          id:,
          group:,
          title:,
          required: @required,
          show_actions: !@grouped_controls,
          empty_state_message:,
          **system_arguments
        )
      }

      # rubocop:disable Metrics/ParameterLists
      def initialize(title: nil, description: nil, templates: [], template_label: nil, required: false,
                     grouped_controls: false, selected_empty_state: nil)
        @title = title
        @description = description
        @templates = templates
        @template_label = template_label
        @required = required
        @grouped_controls = grouped_controls
        @selected_empty_state = selected_empty_state
        @aria_live_translations = load_translations
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def load_translations
        {
          added: I18n.t('shared.sortable_lists.aria_live_update.added'),
          list_order_changed: I18n.t('shared.sortable_lists.aria_live_update.list_order_changed'),
          move_down: I18n.t('shared.sortable_lists.aria_live_update.move_down'),
          move_up: I18n.t('shared.sortable_lists.aria_live_update.move_up'),
          removed: I18n.t('shared.sortable_lists.aria_live_update.removed')
        }.to_json
      end
    end
  end
end
