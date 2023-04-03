# frozen_string_literal: true

module Sidebar
  # Navigation item component
  # @example
  #  <%= render Sidebar::Item::ItemComponent.new(label: 'Home', icon: 'home', url: root_path) %>
  class ItemComponent < Component
    def initialize(label:, icon:, url:)
      @label = label
      @icon = icon
      @url = url
    end
  end
end
