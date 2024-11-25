# frozen_string_literal: true

module Pathogen
  # This file defines the Pathogen::TabsPanel component, which is used to render sets of tabs
  # as well as any inline 'right-side' components (buttons, filter, etc.)
  class TabsPanel < Pathogen::Component
    TAG_DEFAULT = :nav
    TAG_OPTIONS = [TAG_DEFAULT, :div].freeze

    TYPE_DEFAULT = 'default'
    TYPE_OPTIONS = [TYPE_DEFAULT, 'underline'].freeze

    BODY_TAG_DEFAULT = :ul
    BODY_DEFAULT_CLASSES = 'flex flex-wrap text-sm font-medium text-center ' \
                           'text-slate-500 border-b border-slate-200 ' \
                           'dark:border-slate-700 dark:text-slate-400'
    renders_many :tabs, lambda { |count: nil, selected: false, **system_arguments|
      Pathogen::TabsPanel::Tab.new(
        selected: selected,
        tab_type: @type,
        controls: @id,
        count: count,
        **system_arguments
      )
    }

    # rubocop:disable Metrics/ParameterLists
    def initialize(id:, label: '', tag: TAG_DEFAULT, type: TYPE_DEFAULT, body_arguments: {}, **system_arguments)
      @id = id
      @type = fetch_or_fallback(TYPE_OPTIONS, type, TYPE_DEFAULT)
      @system_arguments = system_arguments
      @body_arguments = body_arguments

      @system_arguments[:tag] = fetch_or_fallback(TAG_OPTIONS, tag, TAG_DEFAULT)
      @system_arguments[:id] = @id
      @body_arguments[:tag] = BODY_TAG_DEFAULT
      @body_arguments[:classes] = class_names(BODY_DEFAULT_CLASSES)
      @body_arguments[:role] = 'tablist'
      @body_arguments[:'aria-label'] = label
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
