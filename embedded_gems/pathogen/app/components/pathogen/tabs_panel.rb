# frozen_string_literal: true

module Pathogen
  # 🎯 TabsPanel Component
  # A fully accessible tab panel implementation following WAI-ARIA Tabs Pattern
  # Uses Turbo Drive for full page navigation with morphing
  # @see https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
  class TabsPanel < Pathogen::Component
    TAG_DEFAULT = :div
    TAG_OPTIONS = [TAG_DEFAULT].freeze

    TYPE_DEFAULT = 'underline'
    TYPE_OPTIONS = ['default', TYPE_DEFAULT].freeze

    BODY_TAG_DEFAULT = :ul
    BODY_DEFAULT_CLASSES = 'flex flex-wrap -mb-px text-sm font-medium text-center ' \
                           'text-slate-500 border-b border-slate-200 dark:border-slate-700 ' \
                           'dark:text-slate-400 w-full'

    # 📝 Renders individual tab elements with proper ARIA attributes
    renders_many :tabs, lambda { |options = {}|
      Pathogen::TabsPanel::Tab.new(
        options.merge(
          selected: options[:selected] || false,
          tab_type: @type,
          controls: options[:controls] || @id,
          tablist_id: @id
        )
      )
    }

    # 🚀 Initialize a new TabsPanel component
    # @param id [String] Unique identifier for the tab panel
    # @param label [String] Accessible label for the tab list
    # @param type [String] Visual style of the tabs
    # @param body_arguments [Hash] Additional arguments for the tab list container
    # @param system_arguments [Hash] Additional system arguments
    def initialize(id:, label: '', type: TYPE_DEFAULT, body_arguments: {}, **system_arguments)
      @id = id
      @type = fetch_or_fallback(TYPE_OPTIONS, type, TYPE_DEFAULT)
      @system_arguments = system_arguments
      @body_arguments = body_arguments
      @label = label

      setup_container_attributes
      setup_tablist_attributes
    end

    private

    def setup_container_attributes
      @system_arguments[:tag] = TAG_DEFAULT
      @system_arguments[:classes] = class_names(
        'w-full',
        @system_arguments[:classes]
      )
      @system_arguments[:id] = @id
    end

    def setup_tablist_attributes
      @body_arguments[:tag] = BODY_TAG_DEFAULT
      @body_arguments[:classes] = class_names(BODY_DEFAULT_CLASSES)
      @body_arguments[:role] = 'tablist'
      @body_arguments[:'aria-orientation'] = 'horizontal'
    end
  end
end
