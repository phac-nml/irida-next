# frozen_string_literal: true

module Viral
  # This component creates the sortable_lists.
  class SortableListsComponent < Viral::Component
    attr_reader :title, :description, :templates, :template_label,
                :required, :aria_live_translations

    renders_many :lists, lambda { |id:, group:, title:, max_items: nil, **system_arguments|
      Viral::SortableList::ListComponent.new(id:, group:, title:, required: @required, max_items:,
                                             **system_arguments)
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
        added: I18n.t('shared.sortable_lists.aria_live_update.added'),
        list_order_changed: I18n.t('shared.sortable_lists.aria_live_update.list_order_changed'),
        move_down: I18n.t('shared.sortable_lists.aria_live_update.move_down'),
        move_up: I18n.t('shared.sortable_lists.aria_live_update.move_up'),
        removed: I18n.t('shared.sortable_lists.aria_live_update.removed')
      }.to_json
    end
  end
end
