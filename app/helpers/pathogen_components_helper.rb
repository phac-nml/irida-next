# frozen_string_literal: true

# 🧩 Helper module for Pathogen UI components
#
# This module provides simple helper methods to render Pathogen form components
# in your views. Instead of writing long render statements, you can use these
# shorter helper methods.
module PathogenComponentsHelper
  # 🎯 Renders any Pathogen::Form component
  #
  # @param component [Symbol] The component name (e.g. :radio_button)
  # @param * [Array] Component positional arguments
  # @param ** [Hash] Component keyword arguments
  # @yield Optional block passed to component
  #
  # @example
  #   <%= p_component(:radio_button, value: "dark", label: "Dark Mode") %>
  def p_component(component, *, **, &)
    klass = "Pathogen::Form::#{component.to_s.camelize}Component".constantize
    render(klass.new(*, **), &)
  end

  # 🔘 Renders a radio button component
  #
  # A simpler way to render radio buttons in your views.
  #
  # @example
  #   <%= p_radio_button(
  #     value: "dark",
  #     label: "Dark Mode",
  #     checked: true
  #   ) %>
  def p_radio_button(...)
    p_component(:radio_button, ...)
  end
end
