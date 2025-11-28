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
  # - Required header for accessibility (aria-labelledby)
  # - Optional subtitle for additional context (aria-describedby)
  # - Four size variants: small, medium, large, xlarge
  # - Dismissible and non-dismissible modes
  # - Dynamic scroll shadows for overflow indication
  # - Focus trap with focus restoration
  # - ESC key and backdrop click handling
  # - Screen reader announcements for open/close events
  # - WCAG AA+ accessibility compliance
  # - Turbo Frame integration support
  #
  # == Usage
  #
  # @example Basic dialog with show button
  #   <%= render Pathogen::DialogComponent.new(size: :medium, dismissible: true) do |dialog| %>
  #     <% dialog.with_show_button(scheme: :primary) do %>
  #       Open Dialog
  #     <% end %>
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
  # @example Dialog with external trigger button
  #   <button type="button" data-action="click->pathogen--dialog#open">Open Dialog</button>
  #   <%= render Pathogen::DialogComponent.new(size: :medium, dismissible: true) do |dialog| %>
  #     <% dialog.with_header do %>
  #       <h2>Dialog Title</h2>
  #     <% end %>
  #     <% dialog.with_body do %>
  #       <p>Dialog content goes here.</p>
  #     <% end %>
  #   <% end %>
  #
  # @example Dialog with subtitle for additional context
  #   <%= render Pathogen::DialogComponent.new(subtitle: "This will permanently delete all data") do |dialog| %>
  #     <% dialog.with_header do %>
  #       <h2>Confirm Deletion</h2>
  #     <% end %>
  #     <% dialog.with_body do %>
  #       <p>Are you sure you want to delete this project?</p>
  #     <% end %>
  #     <% dialog.with_footer do %>
  #       <%= button_tag "Cancel" %>
  #       <%= button_tag "Delete", class: "danger" %>
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

    # Renders the show button that triggers the dialog to open
    # Automatically wires up the button with Stimulus action
    # for seamless integration with the dialog controller
    #
    # @param scheme [Symbol] Button color scheme (:primary, :default, :slate, :danger)
    # @param size [Symbol] Button size (:xs, :sm, :md, :lg, :xl)
    # @param block [Boolean] Whether button should be full-width
    # @param system_arguments [Hash] Additional HTML attributes
    renders_one :show_button, lambda { |scheme: :default, size: :medium, block: false, **system_arguments|
      system_arguments[:id] = "dialog-show-#{@id}"
      system_arguments[:data] ||= {}

      # Append the dialog open action to any existing actions
      existing_action = system_arguments[:data][:action]
      dialog_action = 'click->pathogen--dialog#open'
      system_arguments[:data][:action] = if existing_action.present?
                                           "#{existing_action} #{dialog_action}"
                                         else
                                           dialog_action
                                         end

      Pathogen::Button.new(scheme: scheme, size: size, block: block, **system_arguments)
    }

    attr_reader :id, :size, :dismissible, :initially_open, :wrapper_id, :wrapper_data_attributes, :subtitle,
                :open_announcement, :close_announcement

    # Initialize a new Dialog component
    #
    # Supports both keyword arguments and options hash for backward compatibility
    #
    # @param kwargs [Hash] Dialog configuration and HTML attributes
    # @option kwargs [Symbol] :size Size variant (:small, :medium, :large, :xlarge)
    # @option kwargs [Boolean] :dismissible Whether dialog can be dismissed via ESC/backdrop click (default: true)
    # @option kwargs [Boolean] :open Whether dialog starts in open state (default: false)
    # @option kwargs [String] :subtitle Optional subtitle for additional context (sets aria-describedby)
    # @option kwargs [Hash] :announcements Optional hash with :open and/or :close I18n keys for announcements
    def initialize(**kwargs)
      extract_dialog_options(kwargs)
      @id = kwargs.delete(:id) || self.class.generate_id
      @system_arguments = kwargs
      @wrapper_data_attributes = {}
      @wrapper_id = "#{@id}-wrapper"
      setup_data_attributes
    end

    # Validate that header is provided for accessibility
    def before_render
      raise ArgumentError, 'Dialog requires a header for accessibility (aria-labelledby)' if header.blank?
    end

    # Check if footer should be rendered
    # Footer only renders if content is provided via slot
    #
    # @return [Boolean] true if footer content exists
    def render_footer?
      footer.present?
    end

    # Get the subtitle ID for aria-describedby
    #
    # @return [String, nil] The subtitle element ID if subtitle is present
    def subtitle_id
      "#{id}-subtitle" if subtitle.present?
    end

    private

    # Extract dialog-specific options from kwargs
    def extract_dialog_options(kwargs)
      size = kwargs.delete(:size) || SIZE_DEFAULT
      @size = fetch_or_fallback(SIZE_OPTIONS, size, SIZE_DEFAULT)
      @dismissible = kwargs.delete(:dismissible) { true }
      @initially_open = kwargs.delete(:open) { false }
      @subtitle = kwargs.delete(:subtitle)
      announcements = kwargs.delete(:announcements) || {}
      @open_announcement = announcements[:open] || default_open_announcement
      @close_announcement = announcements[:close] || default_close_announcement
    end

    # Sets up data attributes for Stimulus controller integration
    def setup_data_attributes
      setup_controller_attributes
      setup_announcement_attributes
      merge_outlet_attributes
      setup_non_dismissible_behavior
    end

    # Set controller and values on the wrapper (backdrop container)
    def setup_controller_attributes
      @wrapper_data_attributes[:controller] = 'pathogen--dialog'
      @wrapper_data_attributes['pathogen--dialog-dismissible-value'] = @dismissible
      @wrapper_data_attributes['pathogen--dialog-open-value'] = @initially_open
    end

    # Resolve and add announcement messages (resolve I18n keys server-side)
    def setup_announcement_attributes
      resolved_open = resolve_announcement(@open_announcement) if @open_announcement
      @wrapper_data_attributes['pathogen--dialog-open-announcement-value'] = resolved_open if resolved_open

      resolved_close = resolve_announcement(@close_announcement) if @close_announcement
      @wrapper_data_attributes['pathogen--dialog-close-announcement-value'] = resolved_close if resolved_close
    end

    # Merge outlet data attributes from system_arguments into wrapper_data_attributes
    # This allows parent controllers to connect via Stimulus outlets
    def merge_outlet_attributes
      @system_arguments[:data]&.each do |key, value|
        # Only merge outlet-related attributes (containing "outlet" in the key)
        @wrapper_data_attributes[key] = value if key.to_s.include?('outlet')
      end
    end

    # For non-dismissible dialogs, prevent ESC key default behavior
    # This goes on the dialog element itself
    def setup_non_dismissible_behavior
      return if @dismissible

      @system_arguments[:data] ||= {}
      @system_arguments[:data][:action] = 'keydown.esc->pathogen--dialog#handleEsc'
    end

    # Default I18n key for open announcement
    #
    # @return [String] I18n key for dialog open announcement
    def default_open_announcement
      'pathogen.dialog_component.announcements.open'
    end

    # Default I18n key for close announcement
    #
    # @return [String] I18n key for dialog close announcement
    def default_close_announcement
      'pathogen.dialog_component.announcements.close'
    end

    # Resolve announcement message from I18n key or return as-is if already a message
    #
    # @param [String] key_or_message I18n key or message string
    # @return [String, nil] Resolved message or nil if key doesn't exist
    def resolve_announcement(key_or_message)
      # If it looks like an I18n key (contains dots), try to translate it
      if key_or_message.include?('.')
        I18n.t(key_or_message, default: key_or_message)
      else
        # Otherwise, treat as plain message
        key_or_message
      end
    rescue I18n::MissingTranslationData
      # If translation is missing, return the key as fallback
      key_or_message
    end

    # Get the size CSS class
    #
    # @return [String] Tailwind max-width class
    def size_class
      SIZE_MAPPINGS[@size]
    end
  end
end
