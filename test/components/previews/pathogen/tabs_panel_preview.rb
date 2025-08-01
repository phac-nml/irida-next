# frozen_string_literal: true

module Pathogen
  class TabListPreview < ViewComponent::Preview
    # @!group Basic Usage
    # @label Default
    # Basic tabs with minimal configuration
    # Tests:
    # - Basic tab rendering
    # - Default styling
    # - ARIA attributes
    # - Tab selection
    def default; end

    # @label With Count
    # Tabs with count badges
    # Tests:
    # - Count badge rendering
    # - Badge styling
    # - Dynamic counts
    def with_count; end

    # @label With Icons
    # Tabs with icons
    # Tests:
    # - Icon rendering
    # - Icon alignment
    # - Icon + text combination
    def with_icons; end

    # @!group Edge Cases
    # @label Single Tab
    # Edge case: Single tab
    # Tests:
    # - Single tab behavior
    # - No navigation needed
    # - ARIA states
    def single_tab; end

    # @label Many Tabs
    # Edge case: Many tabs with scrolling
    # Tests:
    # - Horizontal scrolling
    # - Overflow handling
    # - Keyboard navigation
    def many_tabs; end

    # @label All Selected
    # Edge case: Multiple selected tabs
    # Tests:
    # - Selection conflict
    # - First tab priority
    # - ARIA states
    def all_selected; end

    # @label No Selected
    # Edge case: No selected tab
    # Tests:
    # - Default selection
    # - First tab priority
    # - ARIA states
    def no_selected; end
  end
end
