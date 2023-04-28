# frozen_string_literal: true

module Viral
  module Card
    class SectionComponent < Viral::Component
      attr_reader :actions, :title

      def initialize(title: '', border_top: false, border_bottom: false, flush: false, actions: [], **system_arguments) # rubocop:disable Metrics/ParameterLists
        @title = title
        @actions = actions
        @system_arguments = system_arguments
        @system_arguments[:tag] = 'div'
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          'border-gray-200 dark:border-gray-700',
          'border-t': border_top,
          'border-b': border_bottom,
          'p-4 pt-0': !flush
        )
      end
    end
  end
end
