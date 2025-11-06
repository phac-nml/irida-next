# frozen_string_literal: true

module Pathogen
  class TabsNav
    # Panel component for server-side tab panels
    # Renders content for selected panel, spinner for non-selected panels
    #
    # == Accessibility
    # - role="tabpanel" for tab panel semantics
    # - aria-labelledby points to controlling tab ID
    # - aria-hidden="true" for non-selected panels
    # - tabindex="0" for keyboard navigation
    # - CSS hidden class for non-selected panels
    #
    # @example Basic usage
    #   <%= nav.with_panel(id: "summary-panel", tab_id: "summary-tab", selected: true) do %>
    #     <%= render partial: "summary" %>
    #   <% end %>
    class Panel < Pathogen::Component
      # Initialize a new Panel component
      # @param id [String] Unique identifier for the panel (required)
      # @param tab_id [String] ID of the tab that controls this panel (required)
      # @param selected [Boolean] Whether this panel is currently visible (default: false)
      # @param system_arguments [Hash] Additional HTML attributes
      # @raise [ArgumentError] if id or tab_id is missing
      def initialize(id:, tab_id:, selected: false, **system_arguments)
        raise ArgumentError, 'id is required' if id.blank?
        raise ArgumentError, 'tab_id is required' if tab_id.blank?

        @id = id
        @tab_id = tab_id
        @selected = selected
        @system_arguments = system_arguments

        setup_panel_attributes
      end

      # Whether this panel is currently selected/visible
      # @return [Boolean]
      attr_reader :selected

      private

      # Sets up HTML attributes for the panel element
      def setup_panel_attributes
        @system_arguments[:id] = @id
        @system_arguments[:role] = 'tabpanel'
        @system_arguments[:tabindex] = 0
        @system_arguments[:aria] ||= {}
        @system_arguments[:aria][:labelledby] = @tab_id
        @system_arguments[:aria][:hidden] = @selected ? 'false' : 'true'
        @system_arguments[:class] = class_names(
          { 'hidden' => !@selected },
          @system_arguments[:class]
        )
      end
    end
  end
end
