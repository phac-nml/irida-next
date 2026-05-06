# frozen_string_literal: true

module SortableLists
  module V1
    # This component creates the sortable_lists.
    class Component < ::Component
      attr_reader :title, :description, :templates, :template_label,
                  :required, :aria_live_translations, :instructions_id, :interactive

      renders_many :lists, lambda { |id:, title:, interactive: nil, **system_arguments|
        interactive = @interactive if interactive.nil?
        SortableLists::V1::ListComponent.new(id:, title:, required: @required, instructions_id: @instructions_id,
                                             interactive:, **system_arguments)
      }

      # rubocop:disable Metrics/ParameterLists

      def initialize(title: nil, description: nil, templates: [], template_label: nil, required: false,
                     interactive: true)
        @title = title
        @description = description
        @templates = templates
        @template_label = template_label
        @required = required
        @interactive = interactive
        @instructions_id = "sortable-lists-v1-instructions-#{SecureRandom.hex(6)}"
        @aria_live_translations = load_translations
      end

      # rubocop:enable Metrics/ParameterLists

      private

      def load_translations
        {
          added_multiple: I18n.t('shared.sortable_lists.aria_live_update.added_multiple'),
          added_single: I18n.t('shared.sortable_lists.aria_live_update.added_single'),
          move_down: I18n.t('shared.sortable_lists.aria_live_update.move_down'),
          move_up: I18n.t('shared.sortable_lists.aria_live_update.move_up'),
          removed_multiple: I18n.t('shared.sortable_lists.aria_live_update.removed_multiple'),
          removed_single: I18n.t('shared.sortable_lists.aria_live_update.removed_single')
        }.to_json
      end
    end
  end
end
