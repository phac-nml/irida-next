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
        @system_arguments[:'aria-selected'] = @selected
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
          'inline-block p-4 text-light-brand-onneutral bg-light-neutral-primary ' \
            'rounded-t-lg active dark:bg-dark-neutral-primary dark:text-dark-brand-onneutral'
        else
          'inline-block p-4 rounded-t-lg hover:text-light-neutral-emphasis ' \
            'hover:bg-light-default dark:hover:bg-dark-neutral-primary-hover dark:hover:text-dark-onneutral-primary'
        end
      end

      def underline_tab_classes
        if @selected
          'inline-block p-4 text-light-brand-onneutral border-b-2 ' \
            'border-light-brand-primary rounded-t-lg active ' \
            'dark:text-dark-brand-onneutral dark:border-dark-brand-primary'
        else
          'inline-block p-4 border-b-2 border-transparent rounded-t-lg ' \
            'hover:text-neutral-emphasis hover:border-light-neutral-primary ' \
            'dark:hover:text-dark-neutral-onneutral dark:hover:border-dark-neutral-primary'
        end
      end
    end
  end
end
