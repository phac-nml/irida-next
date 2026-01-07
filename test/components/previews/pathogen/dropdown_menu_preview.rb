# frozen_string_literal: true

module Pathogen
  # ViewComponent preview for demonstrating Pathogen::DropdownMenu usage
  # Showcases accessibility features, keyboard navigation, and common integration patterns
  class DropdownMenuPreview < ViewComponent::Preview
    # @!group Pathogen Dropdown Menu Component

    # @label Basic Usage
    # Trigger slot + standard menu items (links/actions)
    def basic_usage; end

    # @label Multi-select (Checkbox) + Apply/Cancel
    # Checkbox items with name/value integration and Apply/Cancel footer actions
    def checkbox_multi_select_with_apply_cancel; end

    # @label Submenu (One Level)
    # Demonstrates a one-level submenu with keyboard + hover support
    def submenu; end

    # @label Embedded In Form + Auto Submit
    # Single-select radio items that can requestSubmit() the nearest form on change
    def in_form_auto_submit; end

    # @!endgroup
  end
end
