# frozen_string_literal: true

module Pathogen
  # Conditionally renders a component around the given content. If the given condition
  # is true, the component will render around the content. If the condition is false, only
  # the content is rendered.
  class ConditionalWrapper < Pathogen::Component
    # @param condition [Boolean] Whether or not to wrap the content in a component.
    # @param component [Class] The component class to use as a wrapper.
    # @param base_component_arguments [Hash] The arguments to pass to the component.
    def initialize(condition:, component: Pathogen::BaseComponent, **base_component_arguments)
      raise ArgumentError, 'condition must be a boolean' unless [true, false].include?(condition)
      raise ArgumentError, 'component must be a Class' unless component.is_a?(Class)
      raise ArgumentError, 'component must inherit from Pathogen::Component' unless component < Pathogen::Component

      @condition = condition
      @component = component
      @base_component_arguments = base_component_arguments
    end

    def call
      return content unless @condition

      @component.new(**@base_component_arguments).render_in(self) { content }
    end
  end
end
