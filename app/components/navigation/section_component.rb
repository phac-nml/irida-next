# frozen_string_literal: true

module Navigation
  # Aside navigation section
  # @example
  #  <%= render Navigation::SectionComponent.new(title: 'Section title') do |section| %>
  #   <%= section.with_item(title: 'Item title', url: '#') %>
  #   <%= section.with_item(title: 'Item title', url: '#') %>
  #  <% end %>
  class SectionComponent < BaseComponent
    renders_many :items, Navigation::ItemComponent

    def initialize(title: nil, seperator: false, fill: false, **system_arguments)
      @title = title
      @seperator = seperator
      @fill = fill
      @system_arguments = system_arguments
    end

    def system_arguments
      @system_arguments.tap do |opts|
        opts[:tag] = 'ul'
        opts[:classes] = class_names(
          @system_arguments[:classes],
          'pt-1 space-y-1'
        )
      end
    end
  end
end
