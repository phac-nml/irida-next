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

      # TODO: fully implement once icons are added to pathogen
      renders_one :icon, Pathogen::Icon

      # rubocop:disable Metrics/ParameterLists
      def initialize(controls:, tab_type:, selected: false, text: '', wrapper_arguments: {}, **system_arguments)
        @controls = controls
        @selected = selected
        @text = text
        @tab_type = tab_type

        @system_arguments = system_arguments
        @wrapper_arguments = wrapper_arguments

        @system_arguments[:tag] = TAG_DEFAULT

        @wrapper_arguments[:tag] = :li
        @wrapper_arguments[:classes] = WRAPPER_CLASSES

        @system_arguments[:'aria-current'] = @selected ? 'page' : 'false'
        @system_arguments[:classes] = generate_tab_classes
        @system_arguments[:'aria-controls'] = @controls
      end
      # rubocop:enable Metrics/ParameterLists

      private

      def generate_tab_classes
        if @tab_type == 'default'
          default_tab_classes
        elsif @tab_type == 'underline'
          underline_tab_classes
        end
      end

      def default_tab_classes
        if @selected
          'inline-block p-4 text-primary-600 bg-slate-100 rounded-t-lg active dark:bg-slate-800 dark:text-primary-500'
        else
          'inline-block p-4 rounded-t-lg hover:text-slate-600
        hover:bg-slate-50 dark:hover:bg-slate-800 dark:hover:text-slate-300'
        end
      end

      def underline_tab_classes
        if @selected
          'inline-block p-4 text-primary-600 border-b-2 border-primary-600
          rounded-t-lg active dark:text-primary-500 dark:border-primary-500'
        else
          'inline-block p-4 border-b-2 border-transparent rounded-t-lg
          hover:text-slate-600 hover:border-slate-300 dark:hover:text-slate-300'
        end
      end
    end
  end
end
