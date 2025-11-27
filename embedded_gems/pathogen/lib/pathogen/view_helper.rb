# frozen_string_literal: true

module Pathogen
  # ViewHelper for pathogen component helpers
  module ViewHelper
    PATHOGEN_COMPONENT_HELPERS = {
      button: 'Pathogen::Button',
      datepicker: 'Pathogen::Datepicker',
      dialog: 'Pathogen::DialogComponent',
      icon: 'Pathogen::Icon',
      link: 'Pathogen::Link',
      radio_button: 'Pathogen::Form::RadioButton'
    }.freeze

    # Define helper methods for components
    PATHOGEN_COMPONENT_HELPERS.each do |name, component|
      define_method "pathogen_#{name}" do |*args, **kwargs, &block|
        render component.constantize.new(*args, **kwargs), &block
      end
    end
  end
end
