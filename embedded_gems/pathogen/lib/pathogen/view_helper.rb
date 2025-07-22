# frozen_string_literal: true

module Pathogen
  # ViewHelper for pathogen component helpers
  module ViewHelper
    PATHOGEN_COMPONENT_HELPERS = {
      icon: 'Pathogen::Icon',
      radio_button_preview: 'Pathogen::Form::RadioButton'
    }.freeze

    PATHOGEN_COMPONENT_HELPERS.each do |name, component|
      define_method "pathogen_#{name}" do |*args, **kwargs, &block|
        render component.constantize.new(*args, **kwargs), &block
      end
    end
  end
end
