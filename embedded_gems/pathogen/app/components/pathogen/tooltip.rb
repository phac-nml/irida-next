# frozen_string_literal: true

module Pathogen
  # Pathogen::Tooltip renders an accessible tooltip using native CSS anchor positioning.
  #
  # This component implements a custom tooltip solution with Primer-inspired design,
  # removing the previous Flowbite dependency. It uses CSS anchor positioning for
  # modern browsers and provides smooth fade-in/scale animations.
  #
  # ## Features
  #
  # - **Native CSS Anchor Positioning**: Positions tooltip relative to trigger element
  #   using CSS `anchor()` function (requires modern browser support: Chrome 125+, Edge 125+)
  # - **Multiple Placements**: Supports `:top`, `:bottom`, `:left`, and `:right` positioning
  # - **Smooth Animations**: Fade-in and scale transition (200ms ease-out timing)
  # - **Accessibility**: Maintains `role="tooltip"` and `aria-describedby` connection
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
  #   </div>
  #
  # @note When using directly, you MUST:
  #   - Wrap trigger and tooltip in a container with `data-controller="pathogen--tooltip"`
  #   - Add `aria-describedby="<tooltip-id>"` to the trigger element (W3C ARIA APG requirement)
  #   - Add `data-pathogen--tooltip-target="trigger"` to the trigger element
  #   - Add `data-pathogen--tooltip-target="target"` to the tooltip element (automatic)
  #   The Stimulus controller will validate these requirements at runtime and log errors if missing.
  #
  # ## Browser Compatibility
  #
  # This component uses CSS anchor positioning, which requires modern browser support:
  # - Chrome 125+ (May 2024)
  # - Edge 125+ (May 2024)
  # - Firefox: Not yet supported (as of January 2025)
  # - Safari: Not yet supported (as of January 2025)
  #
  # For browsers without anchor positioning support, the tooltip uses absolute positioning
  # with inline styles as a fallback. The positioning may not be as precise but remains functional.
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
  # - Toggles visibility classes for smooth animation
  # - Sets `anchor-name` CSS property on trigger element
  #
  # @param text [String] The tooltip text content
  # @param id [String] Unique identifier for the tooltip element (required for aria-describedby)
  # @param placement [Symbol] Position of tooltip relative to trigger (:top, :bottom, :left, :right)
  #   Defaults to `:top`. Invalid values will raise ArgumentError.
  class Tooltip < Pathogen::Component
    VALID_PLACEMENTS = %i[top bottom left right].freeze

    attr_reader :text, :id, :placement

    def initialize(text:, id:, placement: :top)
      @text = text
      @id = id
      @placement = placement

      validate_placement!
    end

    private

    # Validates that placement parameter is one of the allowed values
    # @raise [ArgumentError] if placement is not in VALID_PLACEMENTS
    def validate_placement!
      return if VALID_PLACEMENTS.include?(@placement)

      raise ArgumentError, "placement must be one of: #{VALID_PLACEMENTS.map { |p| ":#{p}" }.join(', ')}"
    end
  end
end
