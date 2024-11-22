# frozen_string_literal: true

module Pathogen
  # This file defines the Pathogen::TabsPanel component, which is used to render sets of tabs
  # as well as any inline 'right-side' components (buttons, filter, etc.)
  class TabsPanel < Pathogen::Component
    TAG_DEFAULT = :nav
    TAG_OPTIONS = [TAG_DEFAULT, :div].freeze

    BODY_TAG_DEFAULT = :ul
    # rubocop:disable Layout/LineLength
    BODY_DEFAULT_CLASSES = 'flex flex-wrap text-sm font-medium text-center text-slate-500 border-b border-slate-200 dark:border-slate-700 dark:text-slate-400'
    # rubocop:enable Layout/LineLength
    renders_many :tabs, lambda { |count: nil, selected: false, **system_arguments|
      Pathogen::TabsPanel::Tab.new(
        selected: selected,
        controls: @id,
        count: count,
        **system_arguments
      )
    }

    def initialize(id:, label: '', tag: TAG_DEFAULT, body_arguments: {}, **system_arguments)
      @id = id
      @system_arguments = system_arguments
      @body_arguments = body_arguments

      @system_arguments[:tag] = fetch_or_fallback(TAG_OPTIONS, tag, TAG_DEFAULT)
      @system_arguments[:id] = @id
      @body_arguments[:tag] = BODY_TAG_DEFAULT
      @body_arguments[:classes] = class_names(BODY_DEFAULT_CLASSES)
      @body_arguments[:role] = 'tablist'
      @body_arguments[:'aria-label'] = label
    end
  end
end
