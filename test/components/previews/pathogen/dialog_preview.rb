# frozen_string_literal: true

module Pathogen
  # ViewComponent preview for demonstrating Pathogen::Dialog usage
  # Showcases accessibility features, sizes, variants, and various configurations
  class DialogPreview < ViewComponent::Preview
    # @!group Pathogen Dialog Component

    # @label Basic Usage & Getting Started
    # Simple examples showing basic dialog functionality with default settings
    def basic_usage; end

    # @label Sizes & Variants
    # Demonstrates all four dialog sizes: small, medium, large, and xlarge
    def sizes_and_variants; end

    # @label Dismissible Behavior
    # Shows dismissible vs non-dismissible dialogs and their use cases
    def dismissible_behavior; end

    # @label Footer & Actions
    # Examples of dialogs with and without footers, action button patterns
    def footer_and_actions; end

    # @label Triggering Dialogs
    # Different ways to trigger dialogs: show_button slot vs external triggers
    def triggering_dialogs; end

    # @label Scroll Behavior
    # Demonstrates scroll shadows for dialogs with long content
    def scroll_behavior; end

    # @label Accessibility Features
    # Focus trap, keyboard navigation, screen reader support, and ARIA patterns
    def accessibility_features; end

    # @label Playground
    # Interactive playground for testing different dialog configurations
    def playground; end

    # @!endgroup
  end
end
