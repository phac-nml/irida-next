# frozen_string_literal: true

module Pathogen
  # 🎯 TabsPanel Component
  # A fully accessible tab panel implementation following WAI-ARIA Tabs Pattern
  # @see https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
  class TabsPanel < Pathogen::Component
    TAG_DEFAULT = :nav
    TAG_OPTIONS = [TAG_DEFAULT, :div].freeze

    TYPE_DEFAULT = 'default'
    TYPE_OPTIONS = [TYPE_DEFAULT, 'underline'].freeze

    BODY_TAG_DEFAULT = :ul
    BODY_DEFAULT_CLASSES = 'flex flex-wrap text-sm font-medium text-center ' \
                           'text-slate-500 border-b border-slate-200 ' \
                           'dark:border-slate-700 dark:text-slate-400'

    # 📝 Renders individual tab elements with proper ARIA attributes
    renders_many :tabs, lambda { |options = {}|
      Pathogen::TabsPanel::Tab.new(
        options.merge(
          selected: options[:selected] || false,
          tab_type: @type,
          controls: options[:controls] || @id
        )
      )
    }

    renders_many :tabs_contents, 'Pathogen::TabsPanel::TabsContent'

    # 🚀 Initialize a new TabsPanel component
    # @param id [String] Unique identifier for the tab panel
    # @param label [String] Accessible label for the tab list
    # @param tag [Symbol] HTML tag to use for the container
    # @param type [String] Visual style of the tabs
    # @param body_arguments [Hash] Additional arguments for the tab list container
    # @param system_arguments [Hash] Additional system arguments
    def initialize(id:, selected_tab:, label: '', tag: TAG_DEFAULT, type: TYPE_DEFAULT, body_arguments: {},
                   **system_arguments)
      @id = id
      @type = fetch_or_fallback(TYPE_OPTIONS, type, TYPE_DEFAULT)
      @system_arguments = system_arguments
      @body_arguments = body_arguments
      @selected_tab = selected_tab

      # 🎨 Set up container attributes
      @system_arguments[:tag] = fetch_or_fallback(TAG_OPTIONS, tag, TAG_DEFAULT)
      @system_arguments[:id] = @id
      @system_arguments[:'aria-label'] = label

      # 🎯 Set up tab list attributes
      @body_arguments[:tag] = BODY_TAG_DEFAULT
      @body_arguments[:classes] = class_names(BODY_DEFAULT_CLASSES)
      @body_arguments[:role] = 'tablist'
      @body_arguments[:'aria-label'] = label
      @body_arguments[:'aria-orientation'] = 'horizontal'
    end
  end
end
