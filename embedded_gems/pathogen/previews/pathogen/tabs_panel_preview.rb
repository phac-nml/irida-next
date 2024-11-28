# frozen_string_literal: true

module Pathogen
  # Preview class for the TabsPanel component
  # This class generates preview examples for the TabsPanel component that can be viewed
  # in the ViewComponent preview interface.
  #
  # Preview methods:
  # - default: Shows basic tabs panel
  # - default_with_count: Demonstrates tabs with count indicators
  # - underline: Shows tabs with underline style
  # - underline_with_count: Shows underlined tabs with count indicators
  class TabsPanelPreview < ViewComponent::Preview
    def default; end
    def default_with_count; end
    def underline; end
    def underline_with_count; end
  end
end
