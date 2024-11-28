# frozen_string_literal: true

module Pathogen
  class TabsPanel
    # This file defines the Pathogen::TabsPanel::Count component, which handles adding a count to the tab when called
    class Count < Pathogen::Component
      TAG_DEFAULT = :span

      def initialize(count: nil, selected: false, **system_arguments)
        @count = count
        @selected = selected
        @system_arguments = system_arguments

        @system_arguments[:tag] = TAG_DEFAULT
        @system_arguments[:classes] = generate_count_classes
      end

      def generate_count_classes
        if @selected
          'bg-neutral-300 text-white text-xs font-medium ms-2 px-2 py-1
          rounded-full dark:bg-neutral-600 dark:text-neutral-200'
        else
          'bg-neutral-300 text-white text-xs font-medium ms-2 px-2 py-1
          rounded-full dark:bg-neutral-600 dark:text-neutral-200'
        end
      end
    end
  end
end
