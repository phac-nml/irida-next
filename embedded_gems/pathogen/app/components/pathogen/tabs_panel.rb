# frozen_string_literal: true

module Pathogen
  # 🎯 TabsPanel Component
  # A navigation-based component for section navigation using Turbo Drive
  # Provides a clean, accessible interface for navigating between sections
  class TabsPanel < Pathogen::Component
    # 🔧 Constants
    TAG_DEFAULT = :nav

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
    # Renders individual navigation links with proper styling
    # @param options [Hash] Configuration options for the tab
    # @option options [Boolean] :selected Whether the tab is selected
    # @option options [String] :href URL for the navigation link
    # @return [Pathogen::TabsPanel::Tab] A new tab instance
    renders_many :tabs, lambda { |options = {}|
      Pathogen::TabsPanel::Tab.new(
        options.merge(
          selected: options[:selected] || false,
          tab_type: 'underline',
          href: options[:href]
        )
      )
    }

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
      @system_arguments[:class] = 'w-full'
    end

    # 🏗️ Sets up list attributes for the navigation
    def setup_list_attributes
      @body_arguments[:tag] = @body_arguments[:tag] || BODY_TAG_DEFAULT
      @body_arguments[:classes] = @body_arguments[:classes].presence || BODY_DEFAULT_CLASSES
      @body_arguments[:id] = "#{@id}-list"
      @body_arguments[:data] = {
        tabs_list_id_value: @id
      }
    end
  end
end
