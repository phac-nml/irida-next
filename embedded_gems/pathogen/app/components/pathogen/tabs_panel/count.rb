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
          'bg-slate-300 text-slate-800 text-xs font-medium ms-2 px-2 py-1
          rounded-full dark:bg-slate-500 dark:text-slate-300'
        else
          'bg-slate-100 text-slate-800 text-xs font-medium ms-2 px-2 py-1
          rounded-full dark:bg-slate-700 dark:text-slate-300'
        end
      end
    end
  end
end
