# frozen_string_literal: true

module Pathogen
  # ViewComponent preview for demonstrating Pathogen::Tooltip usage
  # Showcases placement options, accessibility features, animations, and browser compatibility
  class TooltipPreview < ViewComponent::Preview
    include Pathogen::ViewHelper

    # @!group Pathogen Tooltip Component

    # @label Basic Usage & Getting Started
    # Simple examples showing all four placement options and basic tooltip functionality
    def basic_usage; end

    # @label Accessibility & Keyboard Navigation
    # Demonstrates accessibility features, ARIA patterns, hover/focus triggers, and keyboard support
    def accessibility; end

    # @label Link Component Integration
    # Shows integration with Pathogen::Link component in various real-world contexts
    def link_integration; end

    # @label Advanced Features & Edge Cases
    # Demonstrates long text handling, max-width constraint, animations, and edge cases
    def advanced_features; end

    # @label Browser Compatibility
    # Information about CSS anchor positioning support and fallback behavior
    def browser_compatibility; end

    # @!endgroup
  end
end
