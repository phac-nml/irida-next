# frozen_string_literal: true

module Pathogen
  # 🎯 TabsPanel Component
  # A fully accessible tab panel implementation following WAI-ARIA Tabs Pattern
  # Uses Turbo Drive for full page navigation with morphing
  # @see https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
  class TabsPanel < Pathogen::Component
    # 🔧 Constants
    TAG_DEFAULT = :div
    TAG_OPTIONS = [TAG_DEFAULT].freeze

    BODY_TAG_DEFAULT = :ul
    BODY_DEFAULT_CLASSES = [
      'flex flex-wrap -mb-px',
      'text-sm font-medium text-center',
      'text-slate-500',
      'border-b border-slate-200',
      'dark:border-slate-700 dark:text-slate-400',
      'w-full'
    ].join(' ').freeze

    # 📝 Tab Rendering
    # Renders individual tab elements with proper ARIA attributes
    # @param options [Hash] Configuration options for the tab
    # @option options [Boolean] :selected Whether the tab is selected
    # @option options [String] :controls ID of the controlled panel
    # @return [Pathogen::TabsPanel::Tab] A new tab instance
    renders_many :tabs, lambda { |options = {}|
      Pathogen::TabsPanel::Tab.new(
        options.merge(
          selected: options[:selected] || false,
          tab_type: 'underline',
          controls: options[:controls],
          tablist_id: @id
        )
      )
    }

    # 🚀 Initialize a new TabsPanel component
    # @param id [String] Unique identifier for the tab panel
    # @param label [String] Accessible label for the tab list
    # @param body_arguments [Hash] Additional arguments for the tab list container
    # @param system_arguments [Hash] Additional system arguments
    # @raise [ArgumentError] If required parameters are missing
    def initialize(id:, label: '', body_arguments: {}, **system_arguments)
      @id = id
      @system_arguments = system_arguments
      @body_arguments = body_arguments
      @label = label

      validate_parameters!
      setup_container_attributes
      setup_tablist_attributes
    end

    private

    # 🔍 Validates required parameters
    # @raise [ArgumentError] If id is missing or invalid
    def validate_parameters!
      raise ArgumentError, 'id is required' if @id.blank?
    end

    # 🏗️ Sets up container attributes for the tab panel
    def setup_container_attributes
      @system_arguments[:tag] = TAG_DEFAULT
      @system_arguments[:id] = @id
      @system_arguments[:role] = 'tabpanel'
      @system_arguments[:'aria-labelledby'] = "#{@id}-tablist" if @label.present?
    end

    # 🏗️ Sets up tablist attributes for accessibility
    def setup_tablist_attributes
      @body_arguments[:tag] = BODY_TAG_DEFAULT
      @body_arguments[:classes] = class_names(BODY_DEFAULT_CLASSES)
      @body_arguments[:role] = 'tablist'
      @body_arguments[:'aria-orientation'] = 'horizontal'
      @body_arguments[:'aria-label'] = @label if @label.present?
      @body_arguments[:id] = "#{@id}-tablist"
      @body_arguments[:data] = {
        controller: 'tabs',
        tabs_tablist_id_value: @id
      }
    end
  end
end
