# frozen_string_literal: true

module Pathogen
  # 🎯 TabList Component
  # Renders a navigation panel with tabs, typically used for section navigation within a page.
  # Utilizes Turbo Drive for seamless navigation between sections.
  class TabList < Pathogen::Component
    # 🔧 Default HTML tag for the component's root element.
    TAG_DEFAULT = :nav

    # 💅 Default CSS classes for the root <nav> element.
    SYSTEM_DEFAULT_CLASSES = 'w-full'

    # 🔧 Default HTML tag for the list element containing the tabs.
    BODY_TAG_DEFAULT = :ul
    # 💅 Default CSS classes for the <ul> element containing the tabs.
    BODY_DEFAULT_CLASSES = [
      'w-full',
      'flex flex-wrap -mb-px border-b border-slate-200 dark:border-slate-700',
      'text-sm font-medium text-center',
      'text-slate-500 dark:text-slate-400'
    ].join(' ').freeze

    # 📝 Defines and renders individual navigation tabs.
    # Each tab is an instance of `Pathogen::TabList::Tab`.
    # @param options [Hash] Configuration options for the tab.
    # @option options [Boolean] :selected (false) Whether the tab is currently selected.
    # @option options [String] :href The URL the tab links to.
    # @return [Pathogen::TabList::Tab] A new tab instance.
    renders_many :tabs, lambda { |options = {}|
      Pathogen::TabList::Tab.new(
        options.merge(
          selected: options[:selected] || false,
          tab_type: 'underline', # Assumes Tab component handles its specific underline style
          href: options[:href]
        )
      )
    }

    # 🎨 Renders optional content aligned to the right of the tabs.
    renders_one :right_content

    # 🚀 Initializes a new TabList component.
    # @param id [String] A unique identifier for the tabs panel. This is required.
    # @param label [String] An accessible label for the navigation (aria-label).
    # @param body_arguments [Hash] HTML attributes for the list container (<ul>).
    # @param system_arguments [Hash] HTML attributes for the main container (<nav>).
    # @raise [ArgumentError] if id is not provided.
    def initialize(id:, label: '', body_arguments: {}, **system_arguments)
      raise ArgumentError, 'id is required' if id.blank?

      @system_arguments = system_arguments
      @system_arguments[:id] = id # Assign the provided id
      @body_arguments = body_arguments
      @label = label

      setup_container_attributes
      setup_list_attributes
    end

    private

    # 🏗️ Configures HTML attributes for the main <nav> container.
    def setup_container_attributes
      @system_arguments[:tag] = TAG_DEFAULT
      @system_arguments[:class] = class_names(
        SYSTEM_DEFAULT_CLASSES,
        @system_arguments[:class]
      )
    end

    # 🏗️ Configures HTML attributes for the <ul> list container.
    def setup_list_attributes
      @body_arguments[:tag] = @body_arguments[:tag] || BODY_TAG_DEFAULT

      # Apply default classes unless custom classes are provided.
      custom_classes_provided = @body_arguments[:classes].present?
      @body_arguments[:classes] = custom_classes_provided ? @body_arguments[:classes] : BODY_DEFAULT_CLASSES

      @body_arguments[:id] = "#{@system_arguments[:id]}-list"
      @body_arguments[:role] = 'tablist'
      # id is now guaranteed to be present by the initializer
      @body_arguments[:'aria-label'] = @label if @label.present?
      # Merge data attributes, preserving existing ones.
      @body_arguments[:data] = {
        # Ensure this still works as expected, @system_arguments[:id] is now directly set
        tabs_list_id_value: @system_arguments[:id]
      }.merge(@body_arguments[:data] || {})
    end
  end
end
