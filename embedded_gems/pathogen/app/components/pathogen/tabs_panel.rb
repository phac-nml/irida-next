# frozen_string_literal: true

module Pathogen
  # 🎯 TabsPanel Component
  # A navigation-based component for section navigation using Turbo Drive
  # Provides a clean, accessible interface for navigating between sections
  class TabsPanel < Pathogen::Component
    # 🔧 Constants
    TAG_DEFAULT = :nav # Semantic tag for navigation

    # Default classes for the main <nav> element of the component
    SYSTEM_DEFAULT_CLASSES = [
      'w-full' # Removed border-b from here, border is now handled by children
    ].join(' ').freeze

    BODY_TAG_DEFAULT = :ul
    # Default classes for the <ul> element containing the tabs
    BODY_DEFAULT_CLASSES = [
      'flex flex-wrap -mb-px border-b border-slate-200 dark:border-slate-700', # Added border-b here
      'text-sm font-medium text-center',
      'text-slate-500 dark:text-slate-400'
      # w-full was removed in a previous step, sm:border-b was also removed as border is now always on ul
    ].join(' ').freeze

    # 📝 Tab Rendering
    # Renders individual navigation links with proper styling
    # @param options [Hash] Configuration options for the tab
    # @option options [Boolean] :selected Whether the tab is selected
    # @option options [String] :href URL for the navigation link
    # @return [Pathogen::TabsPanel::Tab] A new tab instance
    renders_many :tabs, lambda { |options = {}|
      Pathogen::TabsPanel::Tab.new(
        options.merge(
          selected: options[:selected] || false,
          tab_type: 'underline', # Assumes Tab component handles its specific underline style
          href: options[:href]
        )
      )
    }

    # 🎨 Renders content that appears on the right side of the tabs
    # @return [Pathogen::BaseComponent] The right content component
    renders_one :right_content

    # 🚀 Initialize a new TabsPanel component
    # @param id [String] Unique identifier for the navigation
    # @param label [String] Accessible label for the navigation
    # @param body_arguments [Hash] Additional arguments for the list container
    # @param system_arguments [Hash] Additional system arguments
    # @raise [ArgumentError] If required parameters are missing
    def initialize(id:, label: '', body_arguments: {}, **system_arguments)
      @id = id
      @system_arguments = system_arguments
      @body_arguments = body_arguments
      @label = label

      validate_parameters!
      setup_container_attributes
      setup_list_attributes
    end

    private

    # 🔍 Validates required parameters
    # @raise [ArgumentError] If id is missing or invalid
    def validate_parameters!
      raise ArgumentError, 'id is required' if @id.blank?
    end

    # 🏗️ Sets up container attributes for the navigation
    def setup_container_attributes
      @system_arguments[:tag] = TAG_DEFAULT
      @system_arguments[:id] = @id
      @system_arguments[:'aria-label'] = @label if @label.present?
      @system_arguments[:class] = class_names(
        SYSTEM_DEFAULT_CLASSES,
        @system_arguments[:class] # Allows for additional classes to be passed in
      )
    end

    # 🏗️ Sets up list attributes for the navigation
    def setup_list_attributes
      @body_arguments[:tag] = @body_arguments[:tag] || BODY_TAG_DEFAULT
      # BODY_DEFAULT_CLASSES now includes the border for the tab list itself
      @body_arguments[:classes] = class_names(
        BODY_DEFAULT_CLASSES,
        @body_arguments[:classes].presence # Use .presence for safety with incoming classes
      )
      @body_arguments[:id] = "#{@id}-list"
      # Merge data attributes to preserve existing ones and add new ones
      @body_arguments[:data] = {
        tabs_list_id_value: @id
      }.merge(@body_arguments[:data] || {})
    end
  end
end
