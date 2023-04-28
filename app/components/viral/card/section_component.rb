# frozen_string_literal: true

module Viral
  module Card
    class SectionComponent < Viral::Component
      attr_reader :title

      renders_many :actions

      def initialize(title: '', border_top: false, border_bottom: false, flush: false, **system_arguments)
        @title = title
        @system_arguments = system_arguments
        @system_arguments[:tag] = 'div'
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          'border-gray-200 dark:border-gray-700',
          'border-t': border_top,
          'border-b': border_bottom,
          'p-4': !flush
        )
      end
    end
  end
end
