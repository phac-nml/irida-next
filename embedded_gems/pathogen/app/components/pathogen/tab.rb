# frozen_string_literal: true

module Pathogen
  class Tab < Pathogen::Component
    TAG_DEFAULT = :a

    WRAPPER_CLASSES = 'inline-flex items-center justify-center mr-2'

    attr_reader :selected

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
