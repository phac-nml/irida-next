# frozen_string_literal: true

module Pathogen
  class DropdownMenu
    # Divider entry.
    class Separator < Pathogen::Component
      def initialize(**system_arguments)
        @system_arguments = system_arguments
      end

      def call
        content_tag(
          :div,
          '',
          **@system_arguments, role: 'separator',
                               class: class_names('my-1 h-px bg-slate-200 dark:bg-slate-700', @system_arguments[:class])
        )
      end
    end
  end
end
