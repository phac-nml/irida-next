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
          move_down: I18n.t('shared.sortable_lists.aria_live_update.move_down'),
          move_up: I18n.t('shared.sortable_lists.aria_live_update.move_up'),
          moved_list_multiple: I18n.t('shared.sortable_lists.aria_live_update.moved_list_multiple'),
          moved_list_single: I18n.t('shared.sortable_lists.aria_live_update.moved_list_single'),
          words_connector: I18n.t('support.array.words_connector'),
          last_word_connector: I18n.t('support.array.last_word_connector'),
          two_words_connector: I18n.t('support.array.two_words_connector')
        }.to_json
      end
    end
  end
end
