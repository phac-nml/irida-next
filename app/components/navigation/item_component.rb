# frozen_string_literal: true

module Navigation
  # Navigation item component
  # @example
  #  <%= render Navigation::ItemComponent.new(label: 'Home', icon: 'home', url: root_path) %>
  class ItemComponent < Component
    def initialize(label:, icon:, url:)
      @label = label
      @icon = icon
      @url = url
    end
  end
end
