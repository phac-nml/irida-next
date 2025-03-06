# frozen_string_literal: true

module Viral
  module Card
    # Section component for the card
    class SectionComponent < Viral::Component
      attr_reader :title

      renders_many :actions

      def initialize(title: '', border_top: false, border_bottom: false, flush: false, **system_arguments)
        @title = title
        @system_arguments = system_arguments
        @system_arguments[:tag] = 'div'
        @system_arguments[:classes] = class_names(
          @system_arguments[:classes],
          'viral-card-section',
          'border-slate-200 dark:border-slate-700',
          'border-t': border_top,
          'border-b': border_bottom,
          'p-4': !flush
        )
      end
    end
  end
end
