# frozen_string_literal: true

module Pathogen
  class Tabs
    # Tab Component
    # Individual tab control within a Tabs component.
    # Implements W3C ARIA tab pattern with keyboard navigation support.
    #
    # @example Basic tab
    #   <%= render Pathogen::Tabs::Tab.new(
    #     id: "tab-1",
    #     label: "Overview",
    #     selected: true
    #   ) %>
    class Tab < Pathogen::Component
      # Base CSS classes for all tabs
      BASE_CLASSES = %w[
        cursor-pointer
        inline-block p-4 rounded-t-lg
        font-semibold transition-colors duration-200
        focus:outline-none focus:ring-2 focus:ring-primary-500
        border-b-2
      ].freeze

      # CSS classes for selected tabs
      SELECTED_CLASSES = %w[
        border-primary-800 dark:border-white
        text-slate-900 dark:text-white
        bg-transparent
      ].freeze

      # CSS classes for unselected tabs
      UNSELECTED_CLASSES = %w[
        border-transparent
        text-slate-700 dark:text-slate-200
        hover:text-slate-900 dark:hover:text-white
        hover:border-slate-700 dark:hover:border-white
      ].freeze

      attr_reader :id, :label, :selected

      # Initialize a new Tab component
      # @param id [String] Unique identifier for the tab (required)
      # @param label [String] Text label for the tab (required)
      # @param selected [Boolean] Whether the tab is initially selected (default: false)
      # @param system_arguments [Hash] Additional HTML attributes
      # @raise [ArgumentError] if id or label is missing
      def initialize(id:, label:, selected: false, **system_arguments)
        raise ArgumentError, 'id is required' if id.blank?
        raise ArgumentError, 'label is required' if label.blank?

        @id = id
        @label = label
        @selected = selected
        @system_arguments = system_arguments

        setup_tab_attributes
      end

      private

      # Sets up HTML and ARIA attributes for the tab button
      def setup_tab_attributes
        @system_arguments[:id] = @id
        @system_arguments[:type] = 'button'
        @system_arguments[:role] = 'tab'
        @system_arguments[:aria] ||= {}
        @system_arguments[:aria][:selected] = @selected.to_s
        @system_arguments[:aria][:controls] = nil # Will be set by JavaScript
        @system_arguments[:tabindex] = @selected ? 0 : -1

        setup_data_attributes
        setup_css_classes
      end

      # Sets up Stimulus data attributes
      def setup_data_attributes
        @system_arguments[:data] ||= {}
        @system_arguments[:data]['pathogen--tabs-target'] = 'tab'
        @system_arguments[:data][:action] = [
          'click->pathogen--tabs#selectTab',
          'keydown->pathogen--tabs#handleKeyDown'
        ].join(' ')
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
