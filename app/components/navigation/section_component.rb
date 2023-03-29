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
    renders_one :action, 'ActionComponent'

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

    class ActionComponent < Component
      def initialize(url: nil, external: false, icon: nil, **system_arguments)
        @url = url
        @external = external
        @icon = icon
        @system_arguments = system_arguments
      end

      def system_arguments
        @system_arguments.tap do |opts|
          if @url.present?
            opts[:tag] = 'a'
            opts[:href] = @url
            opts[:target] = '_blank' if @external
          else
            opts[:tag] = 'button'
            opts[:type] = 'button'
          end
          opts[:classes] = class_names(
            @system_arguments[:classes],
            'Polaris-Navigation__Action'
          )
        end
      end

      def call
        render(BaseComponent.new(**system_arguments)) do
          if @icon.present?
            render(IconComponent.new(name: @icon))
          else
            content
          end
        end
      end
    end
  end
end
