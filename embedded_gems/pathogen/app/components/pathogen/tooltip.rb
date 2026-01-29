# frozen_string_literal: true

module Pathogen
  # Pathogen::Tooltip renders an accessible tooltip using JavaScript-based positioning.
  #
  # This component implements a custom tooltip solution with Primer-inspired design,
  # removing the previous Flowbite dependency. It uses JavaScript positioning via a
  # Stimulus controller for precise placement with viewport boundary detection.
  #
  # ## Features
  #
  # - **JavaScript-Based Positioning**: Calculates optimal position using `getBoundingClientRect()`
  #   with sophisticated viewport boundary detection
  # - **Viewport Boundary Detection**: Automatically detects viewport edges and flips
  #   placement (top ↔ bottom, left ↔ right) to keep tooltips visible
  # - **Position Clamping**: Clamps tooltip position to viewport bounds with 8px padding
  #   to prevent overflow
  # - **Multiple Placements**: Supports `:top`, `:bottom`, `:left`, and `:right` positioning
  # - **Smooth Animations**: Fade-in and scale transition (200ms ease-out timing)
  # - **Accessibility**: Maintains `role="tooltip"`, `aria-describedby`, and `aria-hidden` state
  # - **Content-Adaptive Sizing**: Auto-sizes to content with max-width constraint
  # - **Keyboard Accessible**: Shows on both hover and focus for keyboard navigation
  #
  # ## Usage
  #
  # Tooltips are typically used with `Pathogen::Link` component via the tooltip slot:
  #
  # @example Basic tooltip with default top placement
  #   <%= render Pathogen::Link.new(href: "/samples") do |link| %>
  #     <%= link.with_tooltip(text: "View all samples") %>
  #     Samples
  #   <% end %>
  #
  # @example Tooltip with custom bottom placement
  #   <%= render Pathogen::Link.new(href: "/projects") do |link| %>
  #     <%= link.with_tooltip(text: "Manage your projects", placement: :bottom) %>
  #     Projects
  #   <% end %>
  #
  # @example Tooltip with left placement
  #   <%= render Pathogen::Link.new(href: "/settings") do |link| %>
  #     <%= link.with_tooltip(text: "Configure settings", placement: :left) %>
  #     Settings
  #   <% end %>
  #
  # @example Tooltip with right placement
  #   <%= render Pathogen::Link.new(href: "/help") do |link| %>
  #     <%= link.with_tooltip(text: "Get help and documentation", placement: :right) %>
  #     Help
  #   <% end %>
  #
  # @example Direct component usage (advanced)
  #   <div data-controller="pathogen--tooltip">
  #     <button
  #       aria-describedby="tooltip-123"
  #       data-pathogen--tooltip-target="trigger">
  #       Hover me
  #     </button>
  #     <%= render Pathogen::Tooltip.new(
  #       text: "Helpful information",
  #       id: "tooltip-123",
  #       placement: :bottom
  #     ) %>
  #     <!-- Renders: <span id="tooltip-123" role="tooltip" aria-hidden="true" ...> -->
  #   </div>
  #
  # @note When using directly, you MUST:
  #   - Wrap trigger and tooltip in a container with `data-controller="pathogen--tooltip"`
  #   - Add `aria-describedby="<tooltip-id>"` to the trigger element (W3C ARIA APG requirement)
  #   - Add `data-pathogen--tooltip-target="trigger"` to the trigger element
  #   - Add `data-pathogen--tooltip-target="tooltip"` to the tooltip element (automatic)
  #   The Stimulus controller will validate these requirements at runtime and log errors if missing.
  #
  # ## Browser Compatibility
  #
  # This component uses JavaScript-based positioning for broad browser compatibility:
  # - Works in all modern browsers (Chrome, Firefox, Safari, Edge)
  # - No reliance on cutting-edge CSS features
  # - Requires ES6+ JavaScript support (universally available in modern browsers)
  #
  # The JavaScript approach provides sophisticated features like viewport boundary
  # detection and automatic placement flipping that aren't available in CSS-only solutions.
  #
  # ## Design Philosophy
  #
  # Inspired by GitHub's Primer design system, this tooltip features:
  # - Dark background with white text for high contrast
  # - No arrow/pointer indicator (simplified design)
  # - Subtle shadow for depth
  # - Content-adaptive width with max-w-xs (320px) constraint
  # - Smooth fade-in/scale animation for polished feel
  #
  # ## Technical Implementation
  #
  # The tooltip works in conjunction with a Stimulus controller
  # (`pathogen--tooltip_controller.js`) that:
  # - Listens for `mouseenter`/`mouseleave` events for hover trigger
  # - Listens for `focusin`/`focusout` events for keyboard accessibility
  # - Toggles visibility classes and `aria-hidden` attribute for smooth animation
  # - Calculates optimal position using `getBoundingClientRect()`
  # - Detects viewport boundaries and flips placement when needed (top ↔ bottom, left ↔ right)
  # - Clamps position to viewport bounds to prevent overflow
  # - Applies positioning via inline `top` and `left` styles on the tooltip element
  #
  # @param text [String] The tooltip text content
  # @param id [String] Unique identifier for the tooltip element (required for aria-describedby)
  # @param placement [Symbol] Position of tooltip relative to trigger (:top, :bottom, :left, :right)
  #   Defaults to `:top`. Invalid values will raise ArgumentError.
  # @param system_arguments [Hash] Additional HTML attributes for the tooltip root element
  #   (e.g., `class`, `data`, `aria`). These are merged with required defaults.
  class Tooltip < Pathogen::Component
    VALID_PLACEMENTS = %i[top bottom left right].freeze

    TOOLTIP_BASE_CLASSES = 'fixed z-50 bg-slate-900 dark:bg-slate-700 text-white px-3 py-2 text-sm ' \
                           'font-medium rounded-lg shadow-sm max-w-xs inline-block opacity-0 scale-90 ' \
                           'invisible transition-all duration-200 ease-out'

    ARROW_CLASSES = 'absolute w-2 h-2 bg-slate-900 dark:bg-slate-700 rotate-45'

    attr_reader :text, :placement

    def initialize(text:, id:, placement: :top, **system_arguments)
      @text = text
      @id = id
      @placement = placement
      @system_arguments = system_arguments

      validate_placement!
      setup_system_arguments
    end

    # Returns the CSS transform-origin class based on placement
    # @return [String] Tailwind CSS class for transform origin
    def origin_class
      {
        top: 'origin-bottom',
        bottom: 'origin-top',
        left: 'origin-right',
        right: 'origin-left'
      }[@placement]
    end

    # Renders the tooltip using BaseComponent to handle all HTML attributes
    # @return [Pathogen::BaseComponent] The rendered tooltip component
    def call
      render(Pathogen::BaseComponent.new(**@system_arguments)) do
        safe_join([
                    @text,
                    tag.span(class: ARROW_CLASSES, data: { 'pathogen--tooltip-target': 'arrow' })
                  ])
      end
    end

    private

    # Sets up HTML attributes for the tooltip, merging provided system_arguments
    # with required defaults for accessibility and JavaScript behavior
    def setup_system_arguments
      @system_arguments[:tag] = :span
      @system_arguments[:id] = @id
      # W3C ARIA APG requires role="tooltip" - this is non-overridable
      @system_arguments[:role] = 'tooltip'
      @system_arguments[:aria] = merge_aria_attributes
      @system_arguments[:data] = merge_data_attributes
      @system_arguments[:class] = merge_class_names
    end

    # Merges ARIA attributes with required defaults.
    # Tooltips start hidden per W3C ARIA APG, so aria-hidden="true" is set initially.
    # The Stimulus controller toggles aria-hidden to "false" on show and "true" on hide.
    def merge_aria_attributes
      (@system_arguments[:aria] || {}).reverse_merge(
        hidden: true
      )
    end

    # Merges data attributes with required defaults.
    # The placement value is passed to Floating UI which also supports extended
    # placements like 'top-start', 'bottom-end', etc. via the flip middleware.
    def merge_data_attributes
      (@system_arguments[:data] || {}).reverse_merge(
        'pathogen--tooltip-target': 'tooltip',
        placement: @placement.to_s
      )
    end

    # Builds and merges CSS classes with custom classes
    def merge_class_names
      class_names(
        TOOLTIP_BASE_CLASSES,
        origin_class,
        @system_arguments[:class]
      )
    end

    # Validates that placement parameter is one of the allowed values
    # @raise [ArgumentError] if placement is not in VALID_PLACEMENTS
    def validate_placement!
      return if VALID_PLACEMENTS.include?(@placement)

      raise ArgumentError, "placement must be one of: #{VALID_PLACEMENTS.map { |p| ":#{p}" }.join(', ')}"
    end
  end
end
