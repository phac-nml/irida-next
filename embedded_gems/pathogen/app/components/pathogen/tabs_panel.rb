# frozen_string_literal: true

module Pathogen
  # 🎯 TabsPanel Component
  # Renders a navigation panel with tabs, typically used for section navigation within a page.
  # Utilizes Turbo Drive for seamless navigation between sections.
  class TabsPanel < Pathogen::Component
    # 🔧 Default HTML tag for the component's root element.
    TAG_DEFAULT = :div

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
    # Each tab is an instance of `Pathogen::TabsPanel::Tab`.
    # @param options [Hash] Configuration options for the tab.
    # @option options [Boolean] :selected (false) Whether the tab is currently selected.
    # @option options [String] :href The URL the tab links to.
    # @option options [String] :id Unique identifier for the tab (auto-generated if not provided).
    # @return [Pathogen::TabsPanel::Tab] A new tab instance.
    renders_many :tabs, lambda { |options = {}|
      tab_id = options[:id] || "#{@id}-tab-#{@tab_counter}"
      @tab_counter += 1

      # Track selected tab for aria-labelledby
      @selected_tab_id = tab_id if options[:selected]

      # Build system_arguments for the Tab component
      system_arguments = (options[:system_arguments] || {}).merge(
        role: 'tab',
        'aria-selected': options[:selected] || false,
        'aria-controls': "#{@id}-panel-#{tab_id.split('-').last}"
      )

      tab_options = options.merge(
        selected: options[:selected] || false,
        tab_type: 'underline',
        href: options[:href],
        id: tab_id,
        system_arguments: system_arguments
      )

      Pathogen::TabsPanel::Tab.new(tab_options)
    }

    # 🎨 Renders optional content aligned to the right of the tabs.
    renders_one :right_content

    # 🚀 Initializes a new TabsPanel component.
    # @param id [String] A unique identifier for the tabs panel. This is required.
    # @param label [String] An accessible label for the navigation (aria-label).
    # @param body_arguments [Hash] HTML attributes for the list container (<ul>).
    # @param system_arguments [Hash] HTML attributes for the main container (<nav>).
    # @raise [ArgumentError] if id is not provided.
    def initialize(id:, label: '', body_arguments: {}, **system_arguments)
      raise ArgumentError, 'id is required' if id.blank?

      @id = id
      @tab_counter = 0
      @selected_tab_id = nil
      @system_arguments = system_arguments
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

      # Store nav-specific attributes separately
      @nav_attributes = {
        id: @id,
        class: class_names(
          SYSTEM_DEFAULT_CLASSES,
          'flex flex-col sm:flex-row sm:items-stretch sm:border-b sm:border-slate-200 sm:dark:border-slate-700'
        )
      }
      @nav_attributes[:'aria-label'] = @label if @label.present?
    end

    # 🏗️ Configures HTML attributes for the <ul> list container.
    def setup_list_attributes
      @body_arguments[:tag] = @body_arguments[:tag] || BODY_TAG_DEFAULT

      # Apply default classes unless custom classes are provided.
      custom_classes_provided = @body_arguments[:classes].present?
      @body_arguments[:classes] = custom_classes_provided ? @body_arguments[:classes] : BODY_DEFAULT_CLASSES

      @body_arguments[:id] = "#{@id}-list"
      @body_arguments[:role] = 'tablist'
      # Merge data attributes, preserving existing ones.
      @body_arguments[:data] = {
        tabs_list_id_value: @id
      }.merge(@body_arguments[:data] || {})
    end

    # 🔍 Returns the ID of the currently selected tab for aria-labelledby
    attr_reader :selected_tab_id, :nav_attributes
  end
end
