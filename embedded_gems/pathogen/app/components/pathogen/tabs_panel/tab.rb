# frozen_string_literal: true

module Pathogen
  class TabsPanel
    # This file defines the Pathogen::TabsPanel::Tab component, which handles each individual tab
    class Tab < Pathogen::Component
      TAG_DEFAULT = :a

      WRAPPER_CLASSES = 'inline-flex items-center justify-center mr-2'
      # rubocop:disable Layout/LineLength
      COUNT_CLASSES = 'ml-1 text-sm text-slate-600 dark:text-slate-400 rounded-full bg-slate-100 dark:bg-slate-900 inline-block p-0.5'
      # rubocop:enable Layout/LineLength

      renders_one :count, Pathogen::TabsPanel::Count
      renders_one :icon, Pathogen::Icon

      # rubocop: disable Metrics/ParameterLists
      def initialize(controls:, selected: false, icon_classes: '', text: '',
                     wrapper_arguments: {}, **system_arguments)
        @controls = controls
        @selected = selected
        @icon_classes = icon_classes
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
      # rubocop: enable Metrics/ParameterLists

      def generate_link_classes
        if @selected
          'inline-block p-4 border-b-2 rounded-t-lg text-primary-700
        border-primary-700 active dark:text-primary-500 dark:border-primary-500'
        else
          'inline-block p-4 border-b-2 rounded-t-lg border-transparent
        hover:text-slate-600 hover:border-slate-300 dark:hover:text-slate-300'
        end
      end
    end
  end
end
