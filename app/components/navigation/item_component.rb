# frozen_string_literal: true

module Navigation
  # Navigation item component
  # @example
  #  <%= render Navigation::ItemComponent.new(label: 'Home', icon: 'home', url: root_path) %>
  class ItemComponent < Component
    def initialize(label:, icon:, url:, **system_arguments)
      @label = label
      @icon = icon
      @url = url
      @system_arguments = system_arguments
    end
  end
end
