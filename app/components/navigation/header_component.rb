# frozen_string_literal: true

module Navigation
  # Header component for navigation.
  # Renders a header with a label and an icon.
  # @example
  #  <%= render Navigation::HeaderComponent.new(label: 'Home', icon: 'home', url: root_path) %>
  class HeaderComponent < Component
    def initialize(label:, icon:, url:)
      @label = label
      @icon = icon
      @url = url
    end
  end
end
