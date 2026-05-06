# frozen_string_literal: true

module SortableLists
  module V1
    # This component creates the sortable_lists.
    class Component < ::Component
      attr_reader :title, :description, :templates, :template_label,
                  :required, :aria_live_translations

      renders_many :lists, lambda { |id:, group:, title:, **system_arguments|
        SortableLists::V1::ListComponent.new(id:, group:, title:, required: @required, **system_arguments)
      }

      def initialize(title: nil, description: nil, templates: [], template_label: nil, required: false)
        @title = title
        @description = description
        @templates = templates
        @template_label = template_label
        @required = required
        @aria_live_translations = load_translations
      end

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
