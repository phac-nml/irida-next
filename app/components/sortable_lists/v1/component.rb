# frozen_string_literal: true

module SortableLists
  module V1
    # This component creates the sortable_lists.
    class Component < ::Component
      attr_reader :title, :description, :templates, :template_label,
                  :required, :aria_live_translations, :instructions_id

      renders_many :lists, lambda { |id:, title:, **system_arguments|
        SortableLists::V1::ListComponent.new(id:, title:, required: @required, instructions_id: @instructions_id,
                                             **system_arguments)
      }

      def initialize(title: nil, description: nil, templates: [], template_label: nil, required: false)
        @title = title
        @description = description
        @templates = templates
        @template_label = template_label
        @required = required
        @instructions_id = "sortable-lists-v1-instructions-#{SecureRandom.hex(6)}"
        @aria_live_translations = load_translations
      end

      private

      def load_translations
        {
          added: I18n.t('shared.sortable_lists.aria_live_update.added'),
          move_down: I18n.t('shared.sortable_lists.aria_live_update.move_down'),
          move_up: I18n.t('shared.sortable_lists.aria_live_update.move_up'),
          removed: I18n.t('shared.sortable_lists.aria_live_update.removed')
        }.to_json
      end
    end
  end
end
