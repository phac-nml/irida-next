# frozen_string_literal: true

module Pathogen
  class TabsPanel
    # This file defines the Pathogen::TabsPanel::Tab component, which handles each individual tab
    class Tab < Pathogen::Component
      TAG_DEFAULT = :a

      WRAPPER_CLASSES = 'inline-flex items-center justify-center mr-2'

      renders_one :count, lambda { |**system_arguments|
        Pathogen::TabsPanel::Count.new(
          selected: @selected,
          **system_arguments
        )
      }
      renders_one :icon, Pathogen::Icon

      def initialize(controls:, selected: false, text: '', wrapper_arguments: {}, **system_arguments)
        @controls = controls
        @selected = selected
        @text = text

        @system_arguments = system_arguments
        @wrapper_arguments = wrapper_arguments

        @system_arguments[:tag] = TAG_DEFAULT

        @wrapper_arguments[:tag] = :li
        @wrapper_arguments[:classes] = WRAPPER_CLASSES

        @system_arguments[:'aria-current'] = @selected ? 'page' : 'false'
        @system_arguments[:classes] = generate_link_classes
        @system_arguments[:'aria-controls'] = @controls
      end

      def generate_link_classes
        if @selected
          'inline-block p-4 text-primary-600 bg-slate-100 rounded-t-lg active dark:bg-slate-800 dark:text-primary-500'
        else
          'inline-block p-4 rounded-t-lg hover:text-slate-600
          hover:bg-slate-50 dark:hover:bg-slate-800 dark:hover:text-slate-300'
        end
      end
    end
  end
end
