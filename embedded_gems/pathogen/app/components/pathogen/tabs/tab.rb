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
        inline-block p-4
        font-semibold transition-colors duration-200
        border-b-2
      ].freeze

      # CSS classes for selected tabs (horizontal orientation)
      SELECTED_CLASSES_HORIZONTAL = %w[
        border-primary-800 dark:border-white
        text-slate-900 dark:text-white
        bg-transparent
      ].freeze

      # CSS classes for selected tabs (vertical orientation)
      SELECTED_CLASSES_VERTICAL = %w[
        border-r-primary-800 dark:border-r-white
        text-slate-900 dark:text-white
        bg-transparent
      ].freeze

      # CSS classes for unselected tabs (horizontal orientation)
      UNSELECTED_CLASSES_HORIZONTAL = %w[
        border-transparent
        text-slate-700 dark:text-slate-200
        hover:text-slate-900 dark:hover:text-white
        hover:border-slate-700 dark:hover:border-white
      ].freeze

      # CSS classes for unselected tabs (vertical orientation)
      UNSELECTED_CLASSES_VERTICAL = %w[
        border-r-transparent
        text-slate-700 dark:text-slate-200
        hover:text-slate-900 dark:hover:text-white
        hover:border-r-slate-700 dark:hover:border-r-white
      ].freeze

      # CSS classes for horizontal orientation
      HORIZONTAL_CLASSES = %w[rounded-t-lg].freeze

      # CSS classes for vertical orientation
      VERTICAL_CLASSES = %w[rounded-l-lg border-b-0 border-r-2].freeze

      attr_reader :id, :label, :selected, :orientation

      # Initialize a new Tab component
      # @param id [String] Unique identifier for the tab (required)
      # @param label [String] Text label for the tab (required)
      # @param selected [Boolean] Whether the tab is initially selected (default: false)
      # @param orientation [Symbol] Tab orientation (:horizontal or :vertical, default: :horizontal)
      # @param system_arguments [Hash] Additional HTML attributes
      # @raise [ArgumentError] if id or label is missing
      def initialize(id:, label:, selected: false, orientation: :horizontal, **system_arguments)
        raise ArgumentError, 'id is required' if id.blank?
        raise ArgumentError, 'label is required' if label.blank?

        @id = id
        @label = label
        @selected = selected
        @orientation = orientation
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

      # Sets up CSS classes based on selection state and orientation
      # Note: We apply both selected and unselected classes with aria-selected selectors
      # so that JavaScript can dynamically toggle the appearance by changing aria-selected
      def setup_css_classes
        # Select appropriate state classes based on orientation
        state_classes = if @orientation == :vertical
                          @selected ? SELECTED_CLASSES_VERTICAL : UNSELECTED_CLASSES_VERTICAL
                        else
                          @selected ? SELECTED_CLASSES_HORIZONTAL : UNSELECTED_CLASSES_HORIZONTAL
                        end

        orientation_classes = @orientation == :vertical ? VERTICAL_CLASSES : HORIZONTAL_CLASSES

        @system_arguments[:class] = class_names(
          BASE_CLASSES,
          orientation_classes,
          state_classes,
          @system_arguments[:class]
        )
      end
    end
  end
end
