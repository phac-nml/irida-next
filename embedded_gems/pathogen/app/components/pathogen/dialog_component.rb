# frozen_string_literal: true

module Pathogen
  # Dialog Component
  # Modern, accessible modal dialog component following WCAG AA+ compliance standards.
  # Provides a slot-based API for composing header, body, and footer content with
  # consistent styling, dynamic scroll shadows, and focus trap management.
  #
  # == Features
  #
  # - Slot-based API for header, body, and footer content
  # - Four size variants: small, medium, large, xlarge
  # - Dismissible and non-dismissible modes
  # - Dynamic scroll shadows for overflow indication
  # - Focus trap with focus restoration
  # - ESC key and backdrop click handling
  # - WCAG AA+ accessibility compliance
  # - Turbo Frame integration support
  #
  # == Usage
  #
  # @example Basic dialog
  #   <%= render Pathogen::DialogComponent.new(size: :medium, dismissible: true) do |dialog| %>
  #     <% dialog.with_header do %>
  #       <h2>Dialog Title</h2>
  #     <% end %>
  #     <% dialog.with_body do %>
  #       <p>Dialog content goes here.</p>
  #     <% end %>
  #     <% dialog.with_footer do %>
  #       <%= button_tag "Cancel", type: "button" %>
  #       <%= button_tag "Confirm", type: "button", class: "primary" %>
  #     <% end %>
  #   <% end %>
  #
  # @example Non-dismissible dialog for critical actions
  #   <%= render Pathogen::DialogComponent.new(dismissible: false) do |dialog| %>
  #     <% dialog.with_header do %>
  #       <h2>Warning</h2>
  #     <% end %>
  #     <% dialog.with_body do %>
  #       <p>This action cannot be undone.</p>
  #     <% end %>
  #     <% dialog.with_footer do %>
  #       <%= button_tag "Cancel" %>
  #       <%= button_tag "Delete", class: "danger" %>
  #     <% end %>
  #   <% end %>
  #
  # @example Scrollable content with dynamic shadows
  #   <%= render Pathogen::DialogComponent.new(size: :large) do |dialog| %>
  #     <% dialog.with_header do %>
  #       <h2>Select Items</h2>
  #     <% end %>
  #     <% dialog.with_body do %>
  #       <%= render partial: "long_list_of_items" %>
  #     <% end %>
  #     <% dialog.with_footer do %>
  #       <%= button_tag "Done" %>
  #     <% end %>
  #   <% end %>
  #
  class DialogComponent < Pathogen::Component
    # Size options for the dialog
    SIZE_OPTIONS = %i[small medium large xlarge].freeze
    SIZE_DEFAULT = :medium

    # Size mappings to Tailwind max-width classes
    SIZE_MAPPINGS = {
      small: 'max-w-md',      # 28rem
      medium: 'max-w-2xl',    # 40rem
      large: 'max-w-4xl',     # 56rem
      xlarge: 'max-w-6xl'     # 72rem
    }.freeze

    # Renders the header slot containing title and optional actions
    # Automatically includes close button for dismissible dialogs
    renders_one :header

    # Renders the body slot for main dialog content
    # This area is scrollable when content exceeds available height
    renders_one :body

    # Renders the footer slot for action buttons
    # Only rendered if content is provided
    renders_one :footer

    attr_reader :id, :size, :dismissible, :initially_open, :wrapper_data_attributes

    # Initialize a new Dialog component
    #
    # @param size [Symbol] Size variant (:small, :medium, :large, :xlarge)
    # @param dismissible [Boolean] Whether dialog can be dismissed via ESC/backdrop click
    # @param open [Boolean] Whether dialog starts in open state
    # @param system_arguments [Hash] Additional HTML attributes
    def initialize(size: SIZE_DEFAULT, dismissible: true, open: false, **system_arguments)
      @size = fetch_or_fallback(SIZE_OPTIONS, size, SIZE_DEFAULT)
      @dismissible = dismissible
      @initially_open = open
      @id = self.class.generate_id

      @system_arguments = system_arguments
      @wrapper_data_attributes = {}
      setup_data_attributes
    end

    # Check if footer should be rendered
    # Footer only renders if content is provided via slot
    #
    # @return [Boolean] true if footer content exists
    def render_footer?
      footer.present?
    end

    private

    # Sets up data attributes for Stimulus controller integration
    def setup_data_attributes
      # Set controller and values on the wrapper (backdrop container)
      @wrapper_data_attributes[:controller] = 'pathogen--dialog'
      @wrapper_data_attributes['pathogen--dialog-dismissible-value'] = @dismissible
      @wrapper_data_attributes['pathogen--dialog-open-value'] = @initially_open

      # For non-dismissible dialogs, prevent ESC key default behavior
      # This goes on the dialog element itself
      return if @dismissible

      @system_arguments[:data] ||= {}
      @system_arguments[:data][:action] = 'keydown.esc->pathogen--dialog#handleEsc'
    end

    # Get the size CSS class
    #
    # @return [String] Tailwind max-width class
    def size_class
      SIZE_MAPPINGS[@size]
    end
  end
end
