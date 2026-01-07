# frozen_string_literal: true

module Pathogen
  class DropdownMenu
    # Non-interactive label entry.
    class Label < Pathogen::Component
      def initialize(text:, **system_arguments)
        @text = text
        @system_arguments = system_arguments
      end

      def call
        base_classes = [
          'px-3 py-2 text-xs font-semibold uppercase tracking-wide text-slate-500',
          'dark:text-slate-400'
        ].join(' ')

        content_tag(
          :div,
          @text,
          **@system_arguments, role: 'presentation',
                               class: class_names(
                                 base_classes,
                                 @system_arguments[:class]
                               )
        )
      end
    end
  end
end
