# frozen_string_literal: true

module Layout
  module Sidebar
    class SectionComponent < Component
      renders_many :items, ItemComponent

      def initialize(title: nil, **system_arguments)
        @title = title
        @system_arguments = system_arguments
      end

      def system_arguments
        @system_arguments.tap do |opts|
          opts[:tag] = 'ul'
          opts[:classes] = class_names(
            @system_arguments[:classes],
            'Polaris-Navigation__Section',
            'Polaris-Navigation__Section--fill': @fill,
            'Polaris-Navigation__Section--withSeparator': @separator
          )
        end
      end
    end
  end
end
