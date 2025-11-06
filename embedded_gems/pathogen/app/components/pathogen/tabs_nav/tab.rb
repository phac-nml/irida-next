# frozen_string_literal: true

module Pathogen
  class TabsNav
    # Tab Component
    # Individual navigation link within a TabsNav component.
    # Renders as an anchor tag with proper ARIA attributes for current page indication.
    #
    # Visual style matches Pathogen::Tabs::Tab for consistency.
    #
    # @example Basic tab
    #   <%= render Pathogen::TabsNav::Tab.new(
    #     id: "all-tab",
    #     text: "All Projects",
    #     href: projects_path,
    #     selected: true
    #   ) %>
    class Tab < Pathogen::Component
      # Base CSS classes for all tab links (matching Pathogen::Tabs::Tab)
      BASE_CLASSES = %w[
        inline-block p-4
        font-semibold transition-colors duration-200
        border-b-2
        rounded-t-lg
      ].freeze

      # CSS classes for the currently active tab link
      SELECTED_CLASSES = %w[
        border-primary-800 dark:border-white
        text-slate-900 dark:text-white
        bg-transparent
      ].freeze

      # CSS classes for inactive tab links with hover states
      UNSELECTED_CLASSES = %w[
        border-transparent
        text-slate-700 dark:text-slate-200
        hover:text-slate-900 dark:hover:text-white
        hover:border-slate-700 dark:hover:border-white
      ].freeze

      attr_reader :id, :text, :href, :selected

      # Initialize a new Tab link component
      # @param id [String] Unique identifier for the tab link (required)
      # @param text [String] Text label for the tab (required)
      # @param href [String] URL for the navigation link (required)
      # @param selected [Boolean] Whether this tab is currently active (default: false)
      # @param panel_id [String, nil] Optional ID of the panel this tab controls (for aria-controls)
      # @param system_arguments [Hash] Additional HTML attributes
      # @raise [ArgumentError] if id, text, or href is missing
      def initialize(id:, text:, href:, selected: false, panel_id: nil, **system_arguments)
        raise ArgumentError, 'id is required' if id.blank?
        raise ArgumentError, 'text is required' if text.blank?
        raise ArgumentError, 'href is required' if href.blank?

        @id = id
        @text = text
        @href = href
        @selected = selected
        @panel_id = panel_id
        @system_arguments = system_arguments

        setup_link_attributes
      end

      private

      # Sets up HTML and ARIA attributes for the anchor tag
      def setup_link_attributes
        @system_arguments[:id] = @id
        @system_arguments[:href] = @href
        @system_arguments[:aria] ||= {}
        @system_arguments[:aria][:current] = 'page' if @selected
        @system_arguments[:aria][:selected] = @selected ? 'true' : 'false'
        @system_arguments[:aria][:controls] = @panel_id if @panel_id.present?
        @system_arguments[:data] ||= {}
        @system_arguments[:data][:turbo_action] = 'replace'
        @system_arguments[:data][:pathogen__tabs_nav_target] = 'tab'
        @system_arguments[:data][:action] = 'keydown->pathogen--tabs-nav#handleKeydown'

        setup_css_classes
      end

      # Sets up CSS classes based on selection state
      def setup_css_classes
        state_classes = @selected ? SELECTED_CLASSES : UNSELECTED_CLASSES

        @system_arguments[:class] = class_names(
          BASE_CLASSES,
          state_classes,
          @system_arguments[:class]
        )
      end
    end
  end
end
