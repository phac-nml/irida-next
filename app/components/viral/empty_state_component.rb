# frozen_string_literal: true

# Purpose: Renders a visually distinct empty state message, optionally with an icon, description, and an action link.
# It's designed to be used when a section or list has no content to display.
module Viral
  # Represents an empty state component with a title, icon, description, and an optional call to action.
  class EmptyStateComponent < Viral::Component
    attr_reader :icon_name, :title, :description, :action_text, :action_path, :action_method, :data

    # Initializes the component.
    #
    # @param icon_name [String] The name of the icon to display (from Heroicons).
    # @param title [String] The main title text for the empty state.
    # @param description [String, nil] Optional descriptive text below the title.
    # @param action_text [String, nil] Optional text for the action link.
    # @param action_path [String, nil] Optional URL or path for the action link.
    # @param action_method [Symbol, nil] Optional HTTP method for the action link (e.g., :post, :delete).
    # @param data [Hash, nil] Optional data attributes for the action link.
    # rubocop:disable Metrics/ParameterLists
    def initialize(icon_name:, title:, description: nil, action_text: nil, action_path: nil, action_method: nil,
                   data: nil)
      @icon_name = icon_name
      @title = title
      @description = description
      @action_text = action_text
      @action_path = action_path
      @action_method = action_method
      @data = data
    end
    # rubocop:enable Metrics/ParameterLists

    # Determines if the content area (description or action link) should be rendered.
    # @return [Boolean] True if description or action link is present, false otherwise.
    def render_content_area?
      @description.present? || (@action_text.present? && @action_path.present?)
    end

    # Determines if a space is needed before rendering the action link (i.e., if there's a description).
    # @return [Boolean] True if a description is present, false otherwise.
    def space_needed_before_action?
      @description.present?
    end
  end
end
