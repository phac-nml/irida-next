# frozen_string_literal: true

# Pathogen::ViewHelper for pathogen component helpers
module Pathogen
  module ViewHelper
    PATHOGEN_COMPONENT_HELPERS = {
      icon: 'Pathogen::Icon'
    }.freeze

    PATHOGEN_COMPONENT_HELPERS.each do |name, component|
      define_method "pathogen_#{name}" do |*args, **kwargs, &block|
        render component.constantize.new(*args, **kwargs), &block
      end
    end
  end
end
