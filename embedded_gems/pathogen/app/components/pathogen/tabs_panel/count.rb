# frozen_string_literal: true

module Pathogen
  class TabsPanel
    # This file defines the Pathogen::TabsPanel::Count component, which handles adding a count to the tab when called
    class Count < Pathogen::Component
      TAG_DEFAULT = :span

      # rubocop:disable Layout/LineLength
      COUNT_CLASSES = 'ml-1 text-sm text-slate-600 dark:text-slate-400 rounded-full bg-slate-100 dark:bg-slate-900 inline-block p-0.5'
      # rubocop:enable Layout/LineLength

      def initialize(count: nil, **system_arguments)
        @count = count
        @system_arguments = system_arguments

        @system_arguments[:tag] = TAG_DEFAULT
        @system_arguments[:classes] = COUNT_CLASSES
      end
    end
  end
end
