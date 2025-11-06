# frozen_string_literal: true

module Pathogen
  # TabsNav Component
  # Server-side navigation component with tab-like appearance.
  # Uses anchor links with aria-current for WCAG AA+ compliant navigation.
  #
  # Unlike Pathogen::Tabs (client-side tab panels), this component creates
  # navigation links that trigger full page loads with URL changes.
  #
  # == Visual Style
  # Matches Pathogen::Tabs visual appearance with underline style tabs.
  #
  # == Accessibility
  # - Uses semantic <nav> element
  # - aria-current="page" on active link (WCAG 2.4.8)
  # - Keyboard navigation via Stimulus controller:
  #   - Arrow Left/Right: Move focus between tabs (does NOT activate)
  #   - Home: Move focus to first tab
  #   - End: Move focus to last tab
  #   - Space/Enter: Follow link (activate tab)
  # - Manual activation pattern: focus does not activate tabs
  # - Roving tabindex for single tab stop
  # - Server-side state management
  #
  # @example Basic usage with two navigation tabs
  #   <%= render Pathogen::TabsNav.new(id: "project-nav", label: "Project filters") do |nav| %>
  #     <% nav.with_tab(
  #       id: "all-projects",
  #       text: "All Projects",
  #       href: projects_path,
  #       selected: !params[:personal]
  #     ) %>
  #     <% nav.with_tab(
  #       id: "my-projects",
  #       text: "My Projects",
  #       href: projects_path(personal: true),
  #       selected: params[:personal]
  #     ) %>
  #   <% end %>
  #
  # @example With right content area (search, filters, etc.)
  #   <%= render Pathogen::TabsNav.new(id: "project-nav", label: "Project filters") do |nav| %>
  #     <% nav.with_tab(id: "all", text: "All", href: projects_path, selected: true) %>
  #     <% nav.with_tab(id: "personal", text: "Personal", href: projects_path(personal: true)) %>
  #
  #     <% nav.with_right_content do %>
  #       <%= render SearchComponent.new(...) %>
  #     <% end %>
  #   <% end %>
  class TabsNav < Pathogen::Component
    # Renders individual navigation tab links
    # @param id [String] Unique identifier for the tab link
    # @param text [String] Text label for the tab
    # @param href [String] URL for the navigation link
    # @param selected [Boolean] Whether this tab is currently active (default: false)
    # @param system_arguments [Hash] Additional HTML attributes
    # @return [Pathogen::TabsNav::Tab] A new tab link instance
    renders_many :tabs, lambda { |id:, text:, href:, selected: false, **system_arguments|
      Pathogen::TabsNav::Tab.new(
        id: id,
        text: text,
        href: href,
        selected: selected,
        **system_arguments
      )
    }

    # Renders optional content aligned to the right of the tabs
    renders_one :right_content

    # Initialize a new TabsNav component
    # @param id [String] Unique identifier for the navigation element (required)
    # @param label [String] Accessible label for the navigation (required for aria-label)
    # @param system_arguments [Hash] Additional HTML attributes
    # @raise [ArgumentError] if id or label is missing
    def initialize(id:, label:, **system_arguments)
      raise ArgumentError, 'id is required' if id.blank?
      raise ArgumentError, 'label is required' if label.blank?

      @id = id
      @label = label
      @system_arguments = system_arguments

      setup_container_attributes
    end

    # Validates component configuration before rendering
    # ViewComponent lifecycle hook called automatically before rendering
    # @raise [ArgumentError] if validation fails
    def before_render
      validate_tabs!
      validate_unique_ids!
      validate_single_selection!
    end

    private

    # Sets up HTML attributes for the container element
    def setup_container_attributes
      @system_arguments[:id] = @id
      @system_arguments[:aria] ||= {}
      @system_arguments[:aria][:label] = @label
      @system_arguments[:data] ||= {}
      @system_arguments[:data][:controller] = merge_controllers(
        @system_arguments[:data][:controller],
        'pathogen--tabs-nav'
      )
      @system_arguments[:class] = class_names(
        'flex flex-col sm:flex-row sm:items-stretch sm:border-b sm:border-slate-200 sm:dark:border-slate-700 mb-2',
        @system_arguments[:class]
      )
    end

    # Merges controller names, handling nil and string values
    # @param existing [String, nil] Existing controller(s)
    # @param new_controller [String] New controller to add
    # @return [String] Merged controller names
    def merge_controllers(existing, new_controller)
      return new_controller if existing.blank?

      "#{existing} #{new_controller}"
    end

    # Validates that at least one tab is present
    # @raise [ArgumentError] if no tabs are defined
    def validate_tabs!
      raise ArgumentError, 'At least one tab is required' if tabs.empty?
    end

    # Validates that all tab IDs are unique
    # @raise [ArgumentError] if duplicate IDs are found
    def validate_unique_ids!
      tab_ids = tabs.map(&:id)
      return unless tab_ids.uniq.length != tab_ids.length

      raise ArgumentError, 'Duplicate tab IDs found'
    end

    # Validates that at most one tab is selected
    # @raise [ArgumentError] if multiple tabs are selected
    def validate_single_selection!
      selected_count = tabs.count(&:selected)
      return unless selected_count > 1

      raise ArgumentError, "Only one tab can be selected, found #{selected_count}"
    end
  end
end
