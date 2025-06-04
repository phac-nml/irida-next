# frozen_string_literal: true

class PathogenTabsPanelPreview < ViewComponent::Preview
  # @!group Basic Usage
  # @label Default
  # @description Basic tabs with default styling
  def default; end

  # @label With Label
  # @description Tabs with an accessible label
  def with_label; end

  # @label With Count
  # @description Tabs with count badges
  def with_count; end

  # @label With Icons
  # @description Tabs with icons in the labels
  def with_icons; end

  # @label With Custom Body
  # @description Tabs with custom body arguments
  def with_custom_body; end

  # @label With Selected Tab
  # @description Tabs with a pre-selected tab
  def with_selected; end
end
