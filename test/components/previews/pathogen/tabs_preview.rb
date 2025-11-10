# frozen_string_literal: true

module Pathogen
  # ViewComponent preview for demonstrating Pathogen::Tabs usage
  # Showcases accessibility features, keyboard navigation, and various configurations
  class TabsPreview < ViewComponent::Preview
    # @!group Pathogen Tabs Component

    # @label Basic Usage & Getting Started
    # Simple examples showing basic tab functionality with default settings
    def basic_usage; end

    # @label Keyboard Navigation & Accessibility
    # Demonstrates keyboard controls, ARIA patterns, and accessibility features
    def keyboard_and_accessibility; end

    # @label Orientations & Layouts
    # Shows horizontal and vertical tab orientations with different layouts
    def orientations; end

    # @label URL Synchronization
    # Bookmarkable tabs with URL hash syncing and browser navigation
    def url_sync; end

    # @label Advanced Features
    # Default selection, edge cases, and lazy loading patterns
    def advanced_features; end

    # @label Integration Examples
    # Real-world usage patterns with forms, navigation, and content organization
    def integration_examples; end

    # @!endgroup
  end
end
